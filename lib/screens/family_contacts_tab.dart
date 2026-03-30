// lib/screens/family_contacts_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_family_member.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'family_dashboard_screen.dart';

class FamilyContactsTab extends StatefulWidget {
  const FamilyContactsTab({super.key});

  @override
  State<FamilyContactsTab> createState() => _FamilyContactsTabState();
}

class _FamilyContactsTabState extends State<FamilyContactsTab> {
  final _familyService = AiseeFamilyService();
  List<AiseeFamilyMember> _members = [];
  bool _loading = true;
  String? _error;

  final _codeController = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _familyService.close();
    super.dispose();
  }

  Future<String?> _token() async {
    final stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _token();
      if (token == null) return;
      final members = await _familyService.fetchFamily(token);
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

  Future<void> _joinFamily() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _joining = true);
    try {
      final token = await _token();
      if (token == null) return;
      await _familyService.joinFamily(token, code);
      _codeController.clear();
      if (!mounted) return;
      AppToast.snack(context, 'Đã tham gia gia đình');
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      AppToast.snack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: StyleTokens.bodySmall()),
            const SizedBox(height: 12),
            Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _loadMembers();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Thử lại',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_members.isEmpty) return _buildJoinView();
    return _buildMemberList();
  }

  Widget _buildJoinView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/nav/ic_3user.svg',
            width: 36,
            height: 36,
            colorFilter: const ColorFilter.mode(
              StyleTokens.textMuted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có người thân nào',
            style: StyleTokens.titleScreen().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập mã mời để tham gia gia đình',
            style: StyleTokens.bodySmall(),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: StyleTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập mã mời',
              hintStyle: StyleTokens.inputHint(),
              filled: true,
              fillColor: StyleTokens.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StyleTokens.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StyleTokens.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: StyleTokens.buttonPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: _joining ? null : _joinFamily,
                child: Center(
                  child: _joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Tham gia gia đình',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = _members[index];
          return _MemberCard(
            member: member,
            onTap: () async {
              HapticFeedback.lightImpact();
              final token = await _token();
              if (token == null || !mounted) return;
              if (!context.mounted) return;
              await Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (c, a, s) => FamilyDashboardScreen(
                    accessToken: token,
                    member: member,
                  ),
                  transitionsBuilder: (c, a, s, child) {
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
}

// ─── Member card ───────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

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
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/9.x/notionists/png'
                  '?seed=${Uri.encodeComponent(member.id)}'
                  '&size=96&backgroundColor=e8e8e8',
                ),
                onBackgroundImageError: (e, st) {},
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
                      'Chạm để xem thông tin',
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 11,
                        color: StyleTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: StyleTokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
