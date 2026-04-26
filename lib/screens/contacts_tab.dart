import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/in_app_message_controller.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'call_screen.dart';
import 'chat_detail_screen.dart';

/// DiceBear seed avatar URL — generates unique avatar from any string seed.
String _avatarUrl(String seed) =>
    'https://api.dicebear.com/9.x/notionists/png?seed=${Uri.encodeComponent(seed)}&size=96&backgroundColor=e8e8e8';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key, this.aiseeProfile, required this.chatSocket});

  final AiseeUserProfile? aiseeProfile;
  final AiseeChatSocket chatSocket;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final AiseeFamilyService _familyService = AiseeFamilyService();
  final AiseeChatService _chatService = AiseeChatService();

  bool _loading = true;
  String? _error;
  List<AiseeFamilyMember> _contacts = <AiseeFamilyMember>[];
  int _unreadCount = 0;
  bool _callingInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _familyService.close();
    _chatService.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập. Vui lòng đăng nhập lại.';
      });
      return;
    }

    try {
      final List<AiseeFamilyMember> family = await _familyService.fetchFamily(
        tokens.accessToken,
      );
      int unread = 0;
      try {
        unread = await _chatService.fetchUnreadCount(tokens.accessToken);
      } catch (_) {}
      if (!mounted) return;
      AiseeInAppMessageController.instance.rememberContacts(family);
      setState(() {
        _contacts = family;
        _unreadCount = unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tải được danh sách liên lạc.';
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  Future<void> _refreshUnreadCount() async {
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) return;
    try {
      final int count = await _chatService.fetchUnreadCount(tokens.accessToken);
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
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
              (BuildContext c, Animation<double> a, Animation<double> s) =>
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
                Animation<double> a,
                Animation<double> s,
                Widget child,
              ) {
                return FadeTransition(
                  opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
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

  // ─── Invite flow ───────────────────────────────────────────

  Future<void> _showInviteFlow() async {
    final String? relationship = await _showRelationshipSheet();
    if (relationship == null || relationship.trim().isEmpty) return;

    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) return;

    try {
      final String code = await _familyService.createInvite(
        tokens.accessToken,
        relationship.trim(),
      );
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.familyLinkCreated,
          parameters: <String, Object?>{'source': 'invite_created'},
        ),
      );
      if (!mounted) return;
      await _showInviteCodeSheet(code);
      // Reload contacts in case someone joined while sheet was open.
      _loadData();
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : 'Không tạo được mã mời.';
      AppToast.show(msg, isError: true);
    }
  }

  Future<String?> _showRelationshipSheet() {
    final TextEditingController ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: StyleTokens.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Mời người thân',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhập mối quan hệ để tạo mã mời',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: StyleTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                // Input
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: StyleTokens.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'VD: Con, Bố, Mẹ, Anh, Chị...',
                    hintStyle: StyleTokens.inputHint(),
                    filled: true,
                    fillColor: StyleTokens.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StyleTokens.cardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StyleTokens.cardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: StyleTokens.buttonPrimary,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (String v) => Navigator.pop(ctx, v),
                ),
                const SizedBox(height: 16),
                // Buttons row
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Material(
                        color: StyleTokens.background,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(ctx),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Huỷ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: StyleTokens.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: StyleTokens.buttonPrimary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(ctx, ctrl.text),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Tạo mã mời',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: StyleTokens.buttonOnPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInviteCodeSheet(String code) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: StyleTokens.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã mời đã tạo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gửi mã này cho người thân để kết nối',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              // Code display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: StyleTokens.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: StyleTokens.cardBorder),
                ),
                child: Center(
                  child: SelectableText(
                    code,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: StyleTokens.buttonPrimary,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Copy button
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: StyleTokens.buttonPrimary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: code));
                      AppToast.show('Đã sao chép mã mời');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SvgPicture.asset(
                            'assets/icons/nav/ic_document.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              StyleTokens.buttonOnPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sao chép mã',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: StyleTokens.buttonOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Close text
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Đóng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: StyleTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Liên lạc. Nhắn tin và gọi điện người thân.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 20),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Nhắn tin và gọi điện người thân.',
            style: StyleTokens.bodySmall().copyWith(fontSize: 12, height: 1.4),
          ),
        ),
        if (_unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StyleTokens.error,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$_unreadCount',
              style: StyleTokens.socialLabel().copyWith(fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: StyleTokens.buttonPrimary),
        ),
      );
    }
    if (_error != null) return _buildErrorState();
    if (_contacts.isEmpty) return _buildEmptyState();
    return _buildContactsList();
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: <Widget>[
          Text(
            _error!,
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 13,
              color: StyleTokens.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Thử lại tải danh sách liên lạc',
            child: Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Thử lại',
                    style: StyleTokens.socialLabel().copyWith(fontSize: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: <Widget>[
        Material(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                SvgPicture.asset(
                  'assets/icons/nav/ic_3user.svg',
                  width: 36,
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có người thân.\nMời qua mã mời bên dưới.',
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInviteButton(),
      ],
    );
  }

  Widget _buildContactsList() {
    return Column(
      children: <Widget>[
        for (int i = 0; i < _contacts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _ContactCard(
            member: _contacts[i],
            onTap: () async {
              HapticFeedback.lightImpact();
              await Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder:
                      (
                        BuildContext c,
                        Animation<double> a,
                        Animation<double> s,
                      ) => ChatDetailScreen(
                        contact: _contacts[i],
                        currentUserId: widget.aiseeProfile?.id ?? '',
                        chatSocket: widget.chatSocket,
                        onUnreadCleared: () {
                          unawaited(_refreshUnreadCount());
                        },
                      ),
                  transitionsBuilder:
                      (
                        BuildContext c,
                        Animation<double> a,
                        Animation<double> s,
                        Widget child,
                      ) {
                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: a,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        );
                      },
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                ),
              );
              _refreshUnreadCount();
            },
            onVoiceCall: () => _startCall(_contacts[i], 'voice'),
            onVideoCall: () => _startCall(_contacts[i], 'video'),
          ),
        ],
        const SizedBox(height: 16),
        _buildInviteButton(),
      ],
    );
  }

  Widget _buildInviteButton() {
    return Semantics(
      button: true,
      label: 'Mời người thân vào danh sách liên lạc',
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            _showInviteFlow();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Mời người thân',
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Contact card ──────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.member,
    required this.onTap,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final AiseeFamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${member.label}. Chạm để nhắn tin.',
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                // Seed avatar from DiceBear
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: NetworkImage(_avatarUrl(member.id)),
                  onBackgroundImageError: (Object e, StackTrace? st) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        member.label,
                        style: StyleTokens.titleScreen().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chạm để nhắn tin',
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 11,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Gọi thoại ${member.label}',
                  child: IconButton(
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
                    onPressed: onVoiceCall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Gọi video ${member.label}',
                  child: IconButton(
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
                    onPressed: onVideoCall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
