// lib/screens/family_messages_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/aisee_family_member.dart';
import '../services/aisee_chat_service.dart';
import '../services/aisee_chat_socket.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'chat_detail_screen.dart';

String _avatarUrl(String seed) =>
    'https://api.dicebear.com/9.x/notionists/png?seed=${Uri.encodeComponent(seed)}&size=96&backgroundColor=e8e8e8';

class FamilyMessagesTab extends StatefulWidget {
  const FamilyMessagesTab({
    required this.currentUserId,
    required this.chatSocket,
    super.key,
  });

  final String currentUserId;
  final AiseeChatSocket chatSocket;

  @override
  State<FamilyMessagesTab> createState() => _FamilyMessagesTabState();
}

class _FamilyMessagesTabState extends State<FamilyMessagesTab> {
  final _familyService = AiseeFamilyService();
  final _chatService = AiseeChatService();
  List<AiseeFamilyMember> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _familyService.close();
    _chatService.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stored = await AiseeSessionStore.instance.read();
      if (stored == null) return;
      final members = await _familyService.fetchFamily(stored.accessToken);
      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
          'assets/icons/nav/ic_paper.svg',
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
  });

  final AiseeFamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
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
                  children: [
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
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: StyleTokens.buttonPrimary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
