import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../models/aisee_message.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/in_app_message_controller.dart';
import '../services/chat_recording_lifecycle_policy.dart';
import '../services/aisee_session_store.dart';
import '../services/aisee_upload_service.dart';
import '../services/aisee_voice_recorder.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../widgets/app_wordmark.dart';
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.contact,
    required this.currentUserId,
    required this.chatSocket,
    this.onUnreadCleared,
  });

  final AiseeFamilyMember contact;
  final String currentUserId;
  final AiseeChatSocket chatSocket;

  /// Gọi sau khi đánh dấu đã đọc trên máy chủ (ví dụ làm mới badge danh sách).
  final VoidCallback? onUnreadCleared;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final AiseeChatService _chatService = AiseeChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AiseeMessage> _messages = <AiseeMessage>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  StreamSubscription<AiseeMessage>? _socketSub;
  bool _sending = false;
  bool _callingInProgress = false;

  // Media sending state.
  bool _uploadingMedia = false;
  bool _isRecording = false;
  final AiseeUploadService _uploadService = AiseeUploadService();
  final AiseeVoiceRecorder _voiceRecorder = AiseeVoiceRecorder();
  Duration _recordDuration = Duration.zero;
  double _recordDecibels = 0.0;
  StreamSubscription<RecordProgress>? _recorderSub;
  bool _hasText = false;
  Completer<void>? _recordStartCompleter;
  final ChatRecordingLifecyclePolicy _recordingLifecyclePolicy =
      const ChatRecordingLifecyclePolicy();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AiseeInAppMessageController.instance.setActiveConversation(
      widget.contact.id,
    );
    _scrollController.addListener(_onScroll);
    _textController.addListener(() {
      final bool nowHasText = _textController.text.trim().isNotEmpty;
      if (nowHasText != _hasText) {
        setState(() => _hasText = nowHasText);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialMessages();
      _listenSocket();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AiseeInAppMessageController.instance.setActiveConversation(null);
    _socketSub?.cancel();
    _recorderSub?.cancel();
    _voiceRecorder.dispose();
    _uploadService.close();
    _chatService.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contact.id != widget.contact.id) {
      AiseeInAppMessageController.instance.setActiveConversation(
        widget.contact.id,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ChatRecordingLifecycleAction action = _recordingLifecyclePolicy
        .actionFor(
          state: state,
          isRecording: _isRecording || _voiceRecorder.isRecording,
        );
    if (action == ChatRecordingLifecycleAction.cancelRecording) {
      debugPrint(
        '[AiSee:Recorder] Lifecycle interruption: $state -> cancel recording',
      );
      unawaited(_cancelRecordingForLifecycle());
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) return;

    try {
      final List<AiseeMessage> msgs = await _chatService.fetchMessages(
        tokens.accessToken,
        widget.contact.id,
      );
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
        _hasMore = msgs.length >= 50;
      });
      unawaited(_markIncomingUnreadAsRead(msgs));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AiseeApiException
            ? e.message
            : 'Không tải được tin nhắn.';
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingMore = true);

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }

    try {
      final List<AiseeMessage> older = await _chatService.fetchMessages(
        tokens.accessToken,
        widget.contact.id,
        before: _messages.last.id,
      );
      if (!mounted) return;
      setState(() {
        _messages.addAll(older);
        _loadingMore = false;
        _hasMore = older.length >= 50;
      });
      unawaited(_markIncomingUnreadAsRead(older));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadOlderMessages();
    }
  }

  /// Listen to parent socket or create a lightweight one.
  void _listenSocket() {
    _socketSub = widget.chatSocket.onMessage.listen(_onNewMessage);
  }

  void _onNewMessage(AiseeMessage msg) {
    if (msg.senderId != widget.contact.id) return;
    if (!mounted) return;
    setState(() => _messages.insert(0, msg));
    // Fire-and-forget mark read.
    AiseeSessionStore.instance.read().then((AiseeAuthTokens? tokens) {
      if (tokens != null) {
        unawaited(_markReadAndNotify(tokens.accessToken, msg.id));
      }
    });
  }

  bool _isIncomingUnread(AiseeMessage m) {
    if (m.senderId != widget.contact.id || m.isRead) {
      return false;
    }
    final String me = widget.currentUserId;
    if (me.isEmpty) {
      return true;
    }
    return m.receiverId == me;
  }

  /// Tin từ người đối thoại gửi cho mình, chưa đọc — PUT /read (lịch sử không qua socket).
  Future<void> _markIncomingUnreadAsRead(List<AiseeMessage> batch) async {
    final List<AiseeMessage> incomingUnread = batch
        .where(_isIncomingUnread)
        .toList();
    if (incomingUnread.isEmpty) {
      return;
    }
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) {
      return;
    }
    await Future.wait<void>(
      incomingUnread.map((AiseeMessage m) async {
        try {
          await _chatService.markRead(tokens.accessToken, m.id);
        } catch (_) {
          // Tiếp tục các tin còn lại.
        }
      }),
    );
    if (!mounted) {
      return;
    }
    widget.onUnreadCleared?.call();
  }

  Future<void> _markReadAndNotify(String accessToken, String messageId) async {
    try {
      await _chatService.markRead(accessToken, messageId);
    } catch (_) {
      return;
    }
    if (!mounted) {
      return;
    }
    widget.onUnreadCleared?.call();
  }

  Future<void> _startCall(AiseeFamilyMember contact, String callType) async {
    if (_callingInProgress) return;
    _callingInProgress = true;
    HapticFeedback.lightImpact();

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) {
      _callingInProgress = false;
      return;
    }

    try {
      final result = await AiseeCallService().createRoom(
        tokens.accessToken,
        contact.id,
        callType,
      );
      if (!mounted) {
        _callingInProgress = false;
        return;
      }
      await Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder:
              (BuildContext c, Animation<double> anim, Animation<double> s) =>
                  CallScreen(
                    callInfo: AiseeCallInfo(
                      roomName: result.roomName,
                      token: result.token,
                      callType: callType,
                      contact: contact,
                    ),
                  ),
          transitionsBuilder:
              (
                BuildContext c,
                Animation<double> anim,
                Animation<double> s,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: child,
                );
              },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tạo được cuộc gọi';
      AppToast.show(msg, isError: true);
    } finally {
      _callingInProgress = false;
    }
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    _textController.clear();
    _sending = true;

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) {
      _sending = false;
      return;
    }

    try {
      final AiseeMessage msg = await _chatService.sendMessage(
        tokens.accessToken,
        widget.contact.id,
        text,
      );
      if (!mounted) return;
      setState(() => _messages.insert(0, msg));
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        e is AiseeApiException ? e.message : 'Không gửi được tin nhắn.',
        isError: true,
      );
    } finally {
      _sending = false;
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: StyleTokens.surfaceCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: StyleTokens.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _attachOption(
                ctx,
                icon: 'assets/icons/nav/ic_camera.svg',
                label: 'Chụp ảnh',
                semanticsLabel: 'Chụp ảnh bằng camera',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _attachOption(
                ctx,
                icon: 'assets/icons/nav/ic_category.svg',
                label: 'Chọn từ thư viện',
                semanticsLabel: 'Chọn ảnh từ thư viện',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachOption(
    BuildContext ctx, {
    required String icon,
    required String label,
    required String semanticsLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: StyleTokens.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  icon,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final PermissionStatus status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          AppToast.show('Cần quyền camera để chụp ảnh.', isError: true);
        }
        return;
      }
    }
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    await _uploadAndSend(File(picked.path), isImage: true);
  }

  Future<void> _uploadAndSend(File file, {required bool isImage}) async {
    if (_uploadingMedia) return;
    setState(() => _uploadingMedia = true);
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) {
      if (mounted) setState(() => _uploadingMedia = false);
      return;
    }
    try {
      debugPrint(
        '[AiSee:Upload] Begin upload path=${file.path} isImage=$isImage',
      );
      final String url = await _uploadService.uploadFile(
        tokens.accessToken,
        file,
      );
      debugPrint('[AiSee:Upload] Begin sendMessage after upload');
      final AiseeMessage msg = await _chatService.sendMessage(
        tokens.accessToken,
        widget.contact.id,
        '',
        voiceUrl: isImage ? null : url,
        imageUrl: isImage ? url : null,
      );
      if (!mounted) return;
      setState(() {
        _messages.insert(0, msg);
        _uploadingMedia = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingMedia = false);
      AppToast.show(
        e is AiseeApiException ? e.message : 'Gửi không thành công.',
        isError: true,
      );
    }
  }

  Future<void> _startRecording() async {
    _recordStartCompleter = Completer<void>();
    final PermissionStatus micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _recordStartCompleter?.complete();
      if (mounted) {
        AppToast.show('Cần quyền microphone để ghi âm.', isError: true);
      }
      return;
    }
    HapticFeedback.mediumImpact();
    try {
      debugPrint('[AiSee:Recorder] UI start recording request');
      _voiceRecorder.onAutoStop = (File file) {
        if (mounted) {
          setState(() => _isRecording = false);
          _uploadAndSend(file, isImage: false);
        }
      };
      _recorderSub?.cancel();
      _recorderSub = _voiceRecorder.onProgress.listen((RecordProgress p) {
        if (!mounted) return;
        setState(() {
          _recordDuration = p.duration;
          _recordDecibels = p.decibels;
        });
      });
      await _voiceRecorder.start();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      if (mounted) {
        AppToast.show('Không thể ghi âm.', isError: true);
      }
    } finally {
      _recordStartCompleter?.complete();
    }
  }

  Future<void> _stopRecording() async {
    // Wait for start to finish to avoid race condition.
    await _recordStartCompleter?.future;
    debugPrint('[AiSee:Recorder] UI stop recording request');
    _recorderSub?.cancel();
    final File? file = await _voiceRecorder.stop();
    if (!mounted) return;
    setState(() => _isRecording = false);
    if (file != null) await _uploadAndSend(file, isImage: false);
  }

  Future<void> _cancelRecording() async {
    await _recordStartCompleter?.future;
    debugPrint('[AiSee:Recorder] UI cancel recording request');
    _recorderSub?.cancel();
    await _voiceRecorder.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordDuration = Duration.zero;
        _recordDecibels = 0.0;
      });
    }
  }

  Future<void> _cancelRecordingForLifecycle() async {
    if (!_isRecording && !_voiceRecorder.isRecording) {
      return;
    }
    await _recordStartCompleter?.future;
    _recorderSub?.cancel();
    await _voiceRecorder.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
      _recordDecibels = 0.0;
    });
  }

  String _formatTime(DateTime dt) {
    final String h = dt.hour.toString().padLeft(2, '0');
    final String m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        backgroundColor: StyleTokens.background,
        foregroundColor: StyleTokens.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 48,
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.contact.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -0.5,
                  color: StyleTokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const AppWordmark(fontSize: 15),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/nav/ic_voice.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                StyleTokens.buttonPrimary,
                BlendMode.srcIn,
              ),
            ),
            tooltip: 'Gọi thoại',
            onPressed: () => _startCall(widget.contact, 'voice'),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/nav/ic_camera.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                StyleTokens.buttonPrimary,
                BlendMode.srcIn,
              ),
            ),
            tooltip: 'Gọi video',
            onPressed: () => _startCall(widget.contact, 'video'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: StyleTokens.buttonPrimary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _error!,
              style: StyleTokens.bodySmall().copyWith(
                fontSize: 13,
                color: StyleTokens.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadInitialMessages,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Chưa có tin nhắn.\nHãy gửi lời chào!',
          style: StyleTokens.bodySmall().copyWith(fontSize: 13, height: 1.5),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_loadingMore ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: StyleTokens.buttonPrimary,
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildBubble(_messages[index]),
        );
      },
    );
  }

  Widget _buildBubble(AiseeMessage msg) {
    final bool isSent = msg.senderId == widget.currentUserId;
    final double maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.75;

    Widget content;
    if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty) {
      content = _buildImageContent(msg.imageUrl!, maxBubbleWidth);
    } else if (msg.voiceUrl != null && msg.voiceUrl!.isNotEmpty) {
      content = _VoiceBubbleContent(voiceUrl: msg.voiceUrl!, isSent: isSent);
    } else {
      content = Text(
        msg.contentText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isSent ? StyleTokens.buttonOnPrimary : StyleTokens.textPrimary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: isSent
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: EdgeInsets.symmetric(
            horizontal: msg.imageUrl != null ? 4 : 14,
            vertical: msg.imageUrl != null ? 4 : 10,
          ),
          decoration: BoxDecoration(
            color: isSent ? StyleTokens.buttonPrimary : StyleTokens.surfaceCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSent ? 16 : 4),
              bottomRight: Radius.circular(isSent ? 4 : 16),
            ),
          ),
          child: content,
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(msg.createdAt),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: StyleTokens.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(String imageUrl, double maxWidth) {
    return GestureDetector(
      onTap: () => _showFullImage(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: maxWidth - 8,
          fit: BoxFit.cover,
          loadingBuilder:
              (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: maxWidth - 8,
                  height: 150,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StyleTokens.buttonPrimary,
                    ),
                  ),
                );
              },
          errorBuilder: (BuildContext context, Object e, StackTrace? st) {
            return SizedBox(
              width: maxWidth - 8,
              height: 100,
              child: Center(
                child: Text(
                  'Không tải được ảnh',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: StyleTokens.textMuted,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
              child: InteractiveViewer(child: Image.network(imageUrl)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: StyleTokens.navBarBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: _uploadingMedia
              ? _buildUploadingBar()
              : _buildNormalInputBar(),
        ),
      ),
    );
  }

  Widget _buildNormalInputBar() {
    return Row(
      children: <Widget>[
        if (!_isRecording) ...<Widget>[
          Semantics(
            button: true,
            label: 'Đính kèm ảnh',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _showAttachmentSheet,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/nav/ic_plus.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.textMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: _isRecording
              ? _buildRecordingInfo()
              : TextField(
                  controller: _textController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: StyleTokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: false,
                    hintText: 'Nhắn tin...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: StyleTokens.navUnselectedIcon,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
        ),
        const SizedBox(width: 8),
        if (_isRecording)
          _buildStopButton()
        else if (_hasText)
          _buildSendButton()
        else
          _buildMicButton(),
      ],
    );
  }

  Widget _buildSendButton() {
    return Semantics(
      button: true,
      label: 'Gửi tin nhắn',
      child: Material(
        color: StyleTokens.buttonPrimary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _sendMessage,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/nav/ic_send.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.buttonOnPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _micPointerStartX = 0;

  Widget _buildMicButton() {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        _micPointerStartX = event.position.dx;
        _startRecording();
      },
      onPointerUp: (PointerUpEvent event) {
        if (!_isRecording) return;
        final double dx = event.position.dx - _micPointerStartX;
        if (dx < -100) {
          _cancelRecording();
        } else {
          _stopRecording();
        }
      },
      child: Semantics(
        button: true,
        label: 'Giữ để ghi âm',
        child: Material(
          color: StyleTokens.buttonPrimary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/nav/ic_voice.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.buttonOnPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingInfo() {
    final String mins = _recordDuration.inMinutes.toString();
    final String secs = (_recordDuration.inSeconds.remainder(
      60,
    )).toString().padLeft(2, '0');
    return Row(
      children: <Widget>[
        const SizedBox(width: 4),
        const _RecordingDot(),
        const SizedBox(width: 8),
        Text(
          '$mins:$secs',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StyleTokens.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildWaveform()),
      ],
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: _stopRecording,
      onLongPress: _cancelRecording,
      child: Semantics(
        button: true,
        label: 'Dừng ghi âm và gửi. Giữ để huỷ.',
        child: Material(
          color: StyleTokens.error,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: StyleTokens.buttonOnPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    final double normalizedDb = ((_recordDecibels + 40) / 60).clamp(0.0, 1.0);
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(20, (int i) {
          final double height = 4 + (normalizedDb * 20 * ((i % 3 + 1) / 3));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUploadingBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: StyleTokens.buttonPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Đang gửi...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: StyleTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: StyleTokens.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _VoiceBubbleContent extends StatefulWidget {
  const _VoiceBubbleContent({required this.voiceUrl, required this.isSent});

  final String voiceUrl;
  final bool isSent;

  @override
  State<_VoiceBubbleContent> createState() => _VoiceBubbleContentState();
}

class _VoiceBubbleContentState extends State<_VoiceBubbleContent> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _durationSub = _player.durationStream.listen((Duration? d) {
      if (!mounted || d == null) return;
      setState(() => _duration = d);
    });

    try {
      final Duration? d = await _player.setUrl(widget.voiceUrl);
      if (d != null && mounted) {
        debugPrint(
          '[AiSee:VoiceBubble] Initial duration=$d url=${widget.voiceUrl}',
        );
        setState(() => _duration = d);
      }
    } catch (e) {
      debugPrint('[AiSee:VoiceBubble] Error loading audio: $e');
    }

    _posSub = _player.positionStream.listen((Duration pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _stateSub = _player.playerStateStream.listen((PlayerState state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _posSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final int mins = d.inMinutes;
    final int secs = d.inSeconds.remainder(60);
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isSent
        ? StyleTokens.buttonOnPrimary
        : StyleTokens.textPrimary;
    final Color mutedColor = widget.isSent
        ? StyleTokens.buttonOnPrimary.withValues(alpha: 0.7)
        : StyleTokens.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          child: SvgPicture.asset(
            _isPlaying
                ? 'assets/icons/nav/ic_pause.svg'
                : 'assets/icons/nav/ic_play.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          height: 4,
          child: LinearProgressIndicator(
            value: _duration.inMilliseconds > 0
                ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
                : 0,
            backgroundColor: mutedColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(_isPlaying ? _position : _duration),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
      ],
    );
  }
}
