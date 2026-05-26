import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/in_app_message_controller.dart';
import '../services/aisee_token_provider.dart';
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
  bool _groupActionBusy = false;

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

    try {
      final List<AiseeFamilyMember>? family = await AiseeTokenProvider.instance
          .withAccessToken(_familyService.fetchFamily);
      if (family == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context).contactsNotLoggedIn;
        });
        return;
      }
      int unread = 0;
      try {
        unread =
            await AiseeTokenProvider.instance.withAccessToken(
              _chatService.fetchUnreadCount,
            ) ??
            0;
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
          : AppLocalizations.of(context).contactsLoadFailed;
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  Future<void> _refreshUnreadCount() async {
    if (!mounted) return;
    try {
      final int? count = await AiseeTokenProvider.instance.withAccessToken(
        _chatService.fetchUnreadCount,
      );
      if (count == null) return;
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _startCall(AiseeFamilyMember contact, String callType) async {
    if (_callingInProgress) return;
    _callingInProgress = true;
    HapticFeedback.lightImpact();

    try {
      final result = await AiseeTokenProvider.instance.withAccessToken(
        (String accessToken) =>
            AiseeCallService().createRoom(accessToken, contact.id, callType),
      );
      if (result == null) {
        _callingInProgress = false;
        return;
      }
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
          : AppLocalizations.of(context).contactsCallCreateFailed;
      AppToast.show(msg, isError: true);
    } finally {
      _callingInProgress = false;
    }
  }

  Future<void> _leaveGroup() async {
    if (_groupActionBusy) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final String? accessToken = await AiseeTokenProvider.instance.accessToken();
    if (!mounted) return;
    if (accessToken == null) {
      AppToast.show(l.contactsSessionExpired, isError: true);
      return;
    }
    setState(() => _groupActionBusy = true);
    try {
      await _familyService.leaveGroup(accessToken);
      if (!mounted) return;
      AppToast.show(l.contactsLeftGroup);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      final String msg = e is AiseeApiException
          ? e.message
          : l.contactsLeaveGroupFailed;
      AppToast.show(msg, isError: true);
    } finally {
      if (mounted) {
        setState(() => _groupActionBusy = false);
      }
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l.contactsLeaveGroupTitle),
          content: Text(l.contactsLeaveGroupBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.contactsCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.contactsLeaveGroupAction),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _leaveGroup();
    }
  }

  // ─── Join group flow ────────────────────────────────────────

  Future<void> _showJoinGroupFlow() {
    final TextEditingController ctrl = TextEditingController();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final AppLocalizations l = AppLocalizations.of(ctx);
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
                  l.contactsJoinGroupTitle,
                  style: aiseeTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.contactsJoinGroupHint,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: StyleTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: aiseeTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '123456',
                    counterText: '',
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
                ),
                const SizedBox(height: 16),
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
                                l.contactsCancel,
                                style: aiseeTextStyle(
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
                          onTap: () async {
                            final String code = ctrl.text.trim();
                            if (code.isEmpty) {
                              AppToast.show(
                                l.contactsPleaseEnterCode,
                                isError: true,
                              );
                              return;
                            }
                            final String? accessToken = await AiseeTokenProvider
                                .instance
                                .accessToken();
                            if (accessToken == null) {
                              if (ctx.mounted) {
                                AppToast.show(
                                  l.contactsSessionExpired,
                                  isError: true,
                                );
                              }
                              return;
                            }
                            try {
                              await _familyService.joinFamily(
                                accessToken,
                                code,
                              );
                              unawaited(
                                AiseeAnalyticsService.instance.track(
                                  AiseeAnalyticsEvent.familyLinkCreated,
                                  parameters: <String, Object?>{
                                    'source': 'invite_joined_user',
                                  },
                                ),
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              AppToast.show(l.contactsJoinedGroup);
                              _loadData();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              final String msg = e is AiseeApiException
                                  ? e.message
                                  : l.contactsJoinFailed;
                              AppToast.show(msg, isError: true);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                l.contactsJoinAction,
                                style: aiseeTextStyle(
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

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l.contactsTabSemantics,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildHeader(l),
          const SizedBox(height: 20),
          _buildBody(l),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            l.contactsTabIntro,
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

  Widget _buildBody(AppLocalizations l) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 48),
        child: Center(
          child: CircularProgressIndicator(color: StyleTokens.buttonPrimary),
        ),
      );
    }
    if (_error != null) return _buildErrorState(l);
    if (_contacts.isEmpty) return _buildEmptyState(l);
    return _buildContactsList(l);
  }

  Widget _buildErrorState(AppLocalizations l) {
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
            label: l.contactsRetryLabel,
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
                    l.contactsRetry,
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

  Widget _buildEmptyState(AppLocalizations l) {
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
                  l.contactsEmpty,
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
        _buildJoinGroupButton(l),
      ],
    );
  }

  Widget _buildContactsList(AppLocalizations l) {
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
        Material(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.contactsWantSwitchGroup,
                  style: aiseeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(l.contactsSwitchGroupHint, style: StyleTokens.bodySmall()),
                const SizedBox(height: 12),
                Material(
                  color: StyleTokens.background,
                  borderRadius: BorderRadius.circular(31),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(31),
                    onTap: _groupActionBusy ? null : _confirmLeaveGroup,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _groupActionBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              l.contactsLeaveCurrentGroup,
                              style: aiseeTextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: StyleTokens.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinGroupButton(AppLocalizations l) {
    return Semantics(
      button: true,
      label: l.contactsEnterCodeButton,
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            _showJoinGroupFlow();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                l.contactsEnterCodeButton,
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
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: '${member.label}. ${l.contactsTapToChat}',
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
                        l.contactsTapToChat,
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
                  label: l.contactsVoiceCallLabel(member.label),
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
                    tooltip: l.contactsVoiceCallTooltip,
                    onPressed: onVoiceCall,
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.contactsVideoCallLabel(member.label),
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
                    tooltip: l.contactsVideoCallTooltip,
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
