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
import 'call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.contact,
    required this.currentUserId,
  });

  final AiseeFamilyMember contact;
  final String currentUserId;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final AiseeChatService _chatService = AiseeChatService();
  final AiseeChatSocket _chatSocket = AiseeChatSocket();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AiseeMessage> _messages = <AiseeMessage>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  StreamSubscription<AiseeMessage>? _socketSub;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _connectSocket();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _chatSocket.disconnect();
    _chatSocket.dispose();
    _chatService.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
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
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AiseeApiException
                ? e.message
                : 'Không tải được tin nhắn.',
          ),
        ),
      );
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || !_hasMore || _messages.isEmpty) return;
    setState(() => _loadingMore = true);

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) {
      setState(() => _loadingMore = false);
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

  Future<void> _connectSocket() async {
    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    await _chatSocket.connect(tokens.accessToken);
    _socketSub = _chatSocket.onMessage.listen(_onNewMessage);
  }

  void _onNewMessage(AiseeMessage msg) {
    if (msg.senderId != widget.contact.id) return;
    if (!mounted) return;
    setState(() => _messages.insert(0, msg));
    AiseeSessionStore.instance.read().then((AiseeAuthTokens? tokens) {
      if (tokens != null) {
        _chatService.markRead(tokens.accessToken, msg.id);
      }
    });
  }

  Future<void> _startCall(
    AiseeFamilyMember contact,
    String callType,
  ) async {
    HapticFeedback.lightImpact();
    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    try {
      final result = await AiseeCallService().createRoom(
        tokens.accessToken,
        contact.id,
        callType,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CallScreen(
            callInfo: AiseeCallInfo(
              roomName: result.roomName,
              token: result.token,
              callType: callType,
              contact: contact,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tạo được cuộc gọi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _sendMessage() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final AiseeAuthTokens? tokens =
        await AiseeSessionStore.instance.read();
    if (tokens == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AiseeApiException
                ? e.message
                : 'Không gửi được tin nhắn.',
          ),
        ),
      );
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
            onPressed: () =>
                _startCall(widget.contact, 'voice'),
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
            onPressed: () =>
                _startCall(widget.contact, 'video'),
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
        MediaQuery.of(context).size.width * 0.75;

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
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: StyleTokens.buttonPrimary,
                child: SvgPicture.asset(
                  'assets/icons/nav/ic_arrow_right.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.buttonOnPrimary,
                    BlendMode.srcIn,
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
