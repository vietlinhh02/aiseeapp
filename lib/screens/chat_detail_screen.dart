import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../models/aisee_message.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.contact,
    required this.currentUserId,
    this.chatSocket,
  });

  final AiseeFamilyMember contact;
  final String currentUserId;

  /// Reuse parent socket if available — avoids duplicate connections.
  final AiseeChatSocket? chatSocket;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
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

  // Only create own socket if parent didn't provide one.
  AiseeChatSocket? _ownSocket;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialMessages();
      _listenSocket();
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _ownSocket?.disconnect();
    _ownSocket?.dispose();
    _chatService.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
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

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) {
      if (mounted) setState(() => _loadingMore = false);
      return;
    }

    try {
      final List<AiseeMessage> older =
          await _chatService.fetchMessages(
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
    final AiseeChatSocket? parentSocket = widget.chatSocket;
    if (parentSocket != null) {
      _socketSub = parentSocket.onMessage.listen(_onNewMessage);
      return;
    }
    // Fallback: create own socket, but don't await connect.
    final AiseeChatSocket sock = AiseeChatSocket();
    _ownSocket = sock;
    _socketSub = sock.onMessage.listen(_onNewMessage);
    AiseeSessionStore.instance.read().then((AiseeAuthTokens? tokens) {
      if (tokens != null && mounted) {
        sock.connect(tokens.accessToken);
      }
    });
  }

  void _onNewMessage(AiseeMessage msg) {
    if (msg.senderId != widget.contact.id) return;
    if (!mounted) return;
    setState(() => _messages.insert(0, msg));
    // Fire-and-forget mark read.
    AiseeSessionStore.instance.read().then((AiseeAuthTokens? tokens) {
      if (tokens != null) {
        unawaited(_chatService.markRead(tokens.accessToken, msg.id));
      }
    });
  }

  Future<void> _startCall(
    AiseeFamilyMember contact,
    String callType,
  ) async {
    if (_callingInProgress) return;
    _callingInProgress = true;
    HapticFeedback.lightImpact();

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
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
          pageBuilder: (BuildContext c, Animation<double> anim, Animation<double> s) => CallScreen(
            callInfo: AiseeCallInfo(
              roomName: result.roomName,
              token: result.token,
              callType: callType,
              contact: contact,
            ),
          ),
          transitionsBuilder: (BuildContext c, Animation<double> anim, Animation<double> s, Widget child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOut,
              ),
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
      AppToast.snack(context, msg, isError: true);
    } finally {
      _callingInProgress = false;
    }
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    _textController.clear();
    _sending = true;

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
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
      AppToast.snack(
        context,
        e is AiseeApiException ? e.message : 'Không gửi được tin nhắn.',
        isError: true,
      );
    } finally {
      _sending = false;
    }
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
        centerTitle: true,
        title: Text(
          widget.contact.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
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
        child: CircularProgressIndicator(
          color: StyleTokens.buttonPrimary,
        ),
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
          style: StyleTokens.bodySmall().copyWith(
            fontSize: 13,
            height: 1.5,
          ),
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
    final double maxBubbleWidth =
        MediaQuery.sizeOf(context).width * 0.75;

    return Column(
      crossAxisAlignment:
          isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSent
                ? StyleTokens.buttonPrimary
                : StyleTokens.surfaceCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isSent ? 16 : 4),
              bottomRight: Radius.circular(isSent ? 4 : 16),
            ),
          ),
          child: Text(
            msg.contentText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isSent
                  ? StyleTokens.buttonOnPrimary
                  : StyleTokens.textPrimary,
            ),
          ),
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

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: StyleTokens.surfaceCard,
        border: Border(
          top: BorderSide(color: StyleTokens.cardBorder),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _textController,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: StyleTokens.surfaceCard,
                  hintText: 'Nhắn tin...',
                  hintStyle: StyleTokens.inputHint(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: StyleTokens.cardBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: StyleTokens.cardBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: StyleTokens.buttonPrimary,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
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
                        'assets/icons/nav/ic_paper.svg',
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
            ),
          ],
        ),
      ),
    );
  }
}
