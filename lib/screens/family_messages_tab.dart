// lib/screens/family_messages_tab.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_call_service.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'call_screen.dart';
import 'chat_detail_screen.dart';

String _avatarUrl(String seed) =>
    'https://api.dicebear.com/9.x/notionists/png?seed=${Uri.encodeComponent(seed)}&size=96&backgroundColor=e8e8e8';

class FamilyMessagesTab extends StatefulWidget {
  const FamilyMessagesTab({
    required this.currentUserId,
    required this.chatSocket,
    required this.familyRosterVersion,
    required this.messagesTabActive,
    super.key,
  });

  final String currentUserId;
  final AiseeChatSocket chatSocket;
  final ValueNotifier<int> familyRosterVersion;
  final bool messagesTabActive;

  @override
  State<FamilyMessagesTab> createState() => _FamilyMessagesTabState();
}

class _FamilyMessagesTabState extends State<FamilyMessagesTab> {
  final _familyService = AiseeFamilyService();
  final _chatService = AiseeChatService();
  List<AiseeFamilyMember> _members = [];
  bool _loading = true;
  String? _error;
  bool _callingInProgress = false;

  late final VoidCallback _onRosterBump;

  @override
  void initState() {
    super.initState();
    _onRosterBump = () {
      if (mounted) {
        unawaited(_load(background: true));
      }
    };
    widget.familyRosterVersion.addListener(_onRosterBump);
    unawaited(_load());
  }

  @override
  void dispose() {
    widget.familyRosterVersion.removeListener(_onRosterBump);
    _familyService.close();
    _chatService.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FamilyMessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.familyRosterVersion != oldWidget.familyRosterVersion) {
      oldWidget.familyRosterVersion.removeListener(_onRosterBump);
      widget.familyRosterVersion.addListener(_onRosterBump);
    }
    if (widget.messagesTabActive && !oldWidget.messagesTabActive) {
      unawaited(_load(background: true));
    }
  }

  Future<void> _load({bool background = false}) async {
    if (!background) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final stored = await AiseeSessionStore.instance.read();
      if (stored == null) {
        if (!background && mounted) {
          setState(() => _loading = false);
        }
        return;
      }
      final members = await _familyService.fetchFamily(stored.accessToken);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!background || _members.isEmpty) {
          _error = e.toString();
        }
      });
    }
  }

  Future<void> _startCall(
    AiseeFamilyMember contact,
    String callType,
  ) async {
    if (_callingInProgress) return;
    _callingInProgress = true;
    HapticFeedback.lightImpact();

    final tokens = await AiseeSessionStore.instance.read();
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
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) =>
              CallScreen(
            callInfo: AiseeCallInfo(
              roomName: result.roomName,
              token: result.token,
              callType: callType,
              contact: contact,
            ),
          ),
          transitionsBuilder: (BuildContext c, Animation<double> a,
              Animation<double> s, Widget child) {
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
      final String msg = 'Không tạo được cuộc gọi';
      AppToast.show(msg, isError: true);
    } finally {
      _callingInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: StyleTokens.buttonPrimary),
      );
    }
    if (_error != null) {
      return Center(child: _buildErrorState());
    }
    if (_members.isEmpty) {
      return Center(child: _buildEmptyState());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = _members[index];
          return _MemberCard(
            member: member,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (BuildContext c, Animation<double> a,
                          Animation<double> s) =>
                      ChatDetailScreen(
                    contact: member,
                    currentUserId: widget.currentUserId,
                    chatSocket: widget.chatSocket,
                  ),
                  transitionsBuilder: (BuildContext c, Animation<double> a,
                      Animation<double> s, Widget child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: a,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                  reverseTransitionDuration: const Duration(milliseconds: 200),
                ),
              );
            },
            onVoiceCall: () => _startCall(member, 'voice'),
            onVideoCall: () => _startCall(member, 'video'),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _error!,
          style: StyleTokens.bodySmall().copyWith(
            fontSize: 13,
            color: StyleTokens.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Material(
          color: StyleTokens.buttonPrimary,
          borderRadius: BorderRadius.circular(31),
          child: InkWell(
            borderRadius: BorderRadius.circular(31),
            onTap: () {
              HapticFeedback.lightImpact();
              _load();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Thử lại',
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/icons/nav/ic_message.svg',
          width: 36,
          height: 36,
          colorFilter: const ColorFilter.mode(
            StyleTokens.textMuted,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chưa có người thân để nhắn tin',
          style: StyleTokens.bodySmall(),
        ),
      ],
    );
  }
}

// ─── Member card ───────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
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
