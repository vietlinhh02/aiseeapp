import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_family_group.dart';
import '../models/aisee_family_member.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../services/in_app_message_controller.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../generated/l10n/app_localizations.dart';
import 'family_dashboard_screen.dart';

class FamilyContactsTab extends StatefulWidget {
  const FamilyContactsTab({
    super.key,
    this.onFamilyListChanged,
    this.familyService,
    this.readAccessToken,
  });

  final VoidCallback? onFamilyListChanged;
  final AiseeFamilyService? familyService;
  final Future<String?> Function()? readAccessToken;

  @override
  State<FamilyContactsTab> createState() => _FamilyContactsTabState();
}

class _FamilyContactsTabState extends State<FamilyContactsTab> {
  late final AiseeFamilyService _familyService;
  late final Future<String?> Function() _readAccessToken;
  late final bool _ownsFamilyService;

  AiseeCurrentGroup? _group;
  List<AiseeFamilyMember> _caredUsers = <AiseeFamilyMember>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _familyService = widget.familyService ?? AiseeFamilyService();
    _readAccessToken = widget.readAccessToken ?? _defaultReadAccessToken;
    _ownsFamilyService = widget.familyService == null;
    _loadGroup();
  }

  @override
  void dispose() {
    if (_ownsFamilyService) {
      _familyService.close();
    }
    super.dispose();
  }

  Future<String?> _defaultReadAccessToken() async {
    final AiseeAuthTokens? stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<String?> _token() => _readAccessToken();

  AiseeFamilyMember _toFamilyMember(AiseeCareGroupPerson person) {
    return AiseeFamilyMember(
      id: person.id,
      email: person.email,
      displayName: person.displayName,
      role: person.accountRole,
      avatarUrl: person.avatarUrl,
    );
  }

  Future<void> _loadGroup({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final String? token = await _token();
      if (token == null) {
        if (mounted && !silent) {
          setState(() => _loading = false);
        }
        return;
      }
      final AiseeCurrentGroup? group = await _familyService.fetchCurrentGroup(
        token,
      );
      final List<AiseeFamilyMember> caredUsers =
          group?.caredUsers.map(_toFamilyMember).toList() ??
          const <AiseeFamilyMember>[];
      if (!mounted) return;
      AiseeInAppMessageController.instance.rememberContacts(caredUsers);
      setState(() {
        _group = group;
        _caredUsers = caredUsers;
        if (!silent) _loading = false;
      });
      widget.onFamilyListChanged?.call();
    } catch (e) {
      if (!mounted) return;
      if (silent) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createInviteCode() async {
    if (_busy) return;
    final String? token = await _token();
    if (token == null) {
      AppToast.show(l10n.familyContactsSessionExpired, isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final String code = await _familyService.createInvite(token, 'family');
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.familyLinkCreated,
          parameters: <String, Object?>{
            'source': 'family_owner_invite_created',
          },
        ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _showInviteCodeSheet(code);
      if (!mounted) return;
      await _loadGroup(silent: true);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted && _busy) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _leaveGroup() async {
    if (_busy) return;
    final String? token = await _token();
    if (token == null) {
      AppToast.show(l10n.familyContactsSessionExpired, isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await _familyService.leaveGroup(token);
      if (!mounted) return;
      AppToast.show(l10n.familyContactsLeftGroup);
      await _loadGroup();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _transferOwnership(AiseeCareGroupPerson target) async {
    if (_busy) return;
    final String? token = await _token();
    if (token == null) {
      AppToast.show(l10n.familyContactsSessionExpired, isError: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await _familyService.transferGroupOwnership(token, target.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.show(l10n.familyContactsOwnershipTransferred(target.label));
      await _loadGroup();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmLeaveGroup() async {
    final bool isOwner = _group?.canManageGroup ?? false;
    final List<AiseeCareGroupPerson> otherFamilyMembers = _otherFamilyMembers;
    if (isOwner && otherFamilyMembers.isEmpty) {
      AppToast.show(l10n.familyContactsCannotLeave, isError: true);
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isOwner
                ? l10n.familyContactsLeaveBeforeTransfer
                : l10n.familyContactsLeaveGroupTitle,
          ),
          content: Text(
            isOwner
                ? l10n.familyContactsLeaveBody
                : l10n.familyContactsLeaveConfirmBody,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isOwner
                    ? l10n.familyContactsTransferOwnership
                    : l10n.familyContactsLeaveGroup,
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (isOwner) {
      _openTransferOwnershipSheet();
      return;
    }
    await _leaveGroup();
  }

  List<AiseeCareGroupPerson> get _otherFamilyMembers {
    final AiseeCurrentGroup? group = _group;
    if (group == null) {
      return const <AiseeCareGroupPerson>[];
    }
    return group.familyMembers
        .where((AiseeCareGroupPerson member) => member.id != group.ownerUserId)
        .toList();
  }

  void _openTransferOwnershipSheet() {
    final List<AiseeCareGroupPerson> otherFamilyMembers = _otherFamilyMembers;
    if (otherFamilyMembers.isEmpty) {
      AppToast.show(l10n.familyContactsNoOtherMember, isError: true);
      return;
    }
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: StyleTokens.surfaceCard,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: StyleTokens.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.familyContactsTransferOwnershipTitle,
                style: aiseeTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.familyContactsSelectNewOwner,
                style: StyleTokens.bodySmall(),
              ),
              const SizedBox(height: 16),
              for (final AiseeCareGroupPerson member
                  in otherFamilyMembers) ...<Widget>[
                Material(
                  color: StyleTokens.background,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _busy ? null : () => _transferOwnership(member),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFE8E8E8),
                            backgroundImage: member.avatarUrl != null
                                ? NetworkImage(member.avatarUrl!)
                                : null,
                            child: member.avatarUrl == null
                                ? Text(
                                    member.label.substring(0, 1).toUpperCase(),
                                    style: aiseeTextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: StyleTokens.textPrimary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  member.label,
                                  style: aiseeTextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: StyleTokens.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.familyContactsFamilyMember,
                                  style: StyleTokens.bodySmall().copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_busy)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            SvgPicture.asset(
                              'assets/icons/nav/ic_arrow_right.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                StyleTokens.textMuted,
                                BlendMode.srcIn,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
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
                l10n.familyContactsInviteCodeSent,
                style: aiseeTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.familyContactsCreateCodeToInvite,
                style: aiseeTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
                    style: aiseeTextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: StyleTokens.buttonPrimary,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      AppToast.show(l10n.familyContactsCodeCopied);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          l10n.familyContactsCopyCode,
                          style: aiseeTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          children: <Widget>[
            Text(_error!, style: StyleTokens.bodySmall()),
            const SizedBox(height: 12),
            Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: _loadGroup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    l10n.remindersRetry,
                    style: aiseeTextStyle(
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
    if (_group == null) {
      return _buildCreateGroupView();
    }
    return _buildGroupView();
  }

  Widget _buildCreateGroupView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 16),
          Text(
            l10n.familyContactsCreateCareGroup,
            style: StyleTokens.titleScreen().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familyContactsCreateCodeToInvite,
            style: StyleTokens.bodySmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: _busy ? null : _createInviteCode,
                child: Center(
                  child: Text(
                    l10n.familyContactsCreateInviteCode,
                    style: aiseeTextStyle(
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

  Widget _buildGroupView() {
    final AiseeCurrentGroup group = _group!;
    return RefreshIndicator(
      onRefresh: _loadGroup,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _GroupSummaryCard(
            group: group,
            busy: _busy,
            onCreateInvite: group.canManageGroup ? _createInviteCode : null,
            onTransferOwnership:
                group.canManageGroup && _otherFamilyMembers.isNotEmpty
                ? _openTransferOwnershipSheet
                : null,
            onLeaveGroup: _confirmLeaveGroup,
          ),
          const SizedBox(height: 16),
          _buildCaredUsersSection(),
          if (group.familyMembers.length > 1) ...<Widget>[
            const SizedBox(height: 16),
            _buildFamilyMembersSection(group.familyMembers),
          ],
        ],
      ),
    );
  }

  Widget _buildCaredUsersSection() {
    if (_caredUsers.isEmpty) {
      return Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.familyContactsNoCaredUsers,
            style: StyleTokens.bodySmall(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.familyContactsCaredUsersSection,
          style: aiseeTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _caredUsers.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          _MemberCard(
            member: _caredUsers[i],
            onTap: () async {
              HapticFeedback.lightImpact();
              final String? token = await _token();
              if (token == null || !mounted) return;
              await Navigator.of(context).push(
                PageRouteBuilder<void>(
                  pageBuilder: (c, a, s) => FamilyDashboardScreen(
                    accessToken: token,
                    member: _caredUsers[i],
                  ),
                  transitionsBuilder: (c, a, s, child) {
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
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFamilyMembersSection(List<AiseeCareGroupPerson> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.familyContactsFamilyMembersSection,
          style: aiseeTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: members.map((AiseeCareGroupPerson member) {
              final String subtitle = member.isOwner
                  ? l10n.familyContactsGroupOwner
                  : l10n.familyContactsFamilyMember;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? Text(
                          member.label.substring(0, 1).toUpperCase(),
                          style: aiseeTextStyle(
                            fontWeight: FontWeight.w700,
                            color: StyleTokens.textPrimary,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  member.label,
                  style: aiseeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                subtitle: Text(subtitle, style: StyleTokens.bodySmall()),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.group,
    required this.busy,
    required this.onLeaveGroup,
    this.onCreateInvite,
    this.onTransferOwnership,
  });

  final AiseeCurrentGroup group;
  final bool busy;
  final VoidCallback onLeaveGroup;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onTransferOwnership;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isOwner = group.canManageGroup;
    final String roleLabel = isOwner
        ? l10n.familyContactsYouAreOwner
        : l10n.familyContactsFamilyMembersSection;
    final Color accent = StyleTokens.buttonPrimary;
    final Color accentSoft = accent.withValues(alpha: 0.08);

    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -14,
            right: -18,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.07,
                child: SvgPicture.asset(
                  'assets/illustrations/family_group_heart.svg',
                  width: 110,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/illustrations/family_group_heart.svg',
                        width: 20,
                        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            group.name,
                            style: aiseeTextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: StyleTokens.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _RolePill(label: roleLabel, isOwner: isOwner),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatTile(
                        label: l10n.familyContactsCaredUser,
                        value: '${group.caredUsers.length}',
                        accent: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatTile(
                        label: l10n.familyContactsFamilyMember,
                        value: '${group.familyMembers.length}',
                        accent: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isOwner
                      ? l10n.familyContactsOnlyOwnerWarning
                      : l10n.familyContactsOnlyOwnerWarning,
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 11.5,
                    height: 1.3,
                    color: StyleTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (onCreateInvite != null)
                      _ActionButton(
                        label: l10n.familyContactsCreateInviteCode,
                        filled: true,
                        busy: busy,
                        onTap: onCreateInvite!,
                      ),
                    if (onTransferOwnership != null)
                      _ActionButton(
                        label: l10n.familyContactsTransferOwnership,
                        busy: busy,
                        onTap: onTransferOwnership!,
                      ),
                    _ActionButton(
                      label: l10n.familyContactsLeaveGroup,
                      busy: busy,
                      onTap: onLeaveGroup,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, required this.isOwner});

  final String label;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final Color accent = StyleTokens.buttonPrimary;
    final Color bg = isOwner
        ? accent.withValues(alpha: 0.10)
        : const Color(0xFFEFEFEF);
    final Color fg = isOwner ? accent : StyleTokens.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isOwner ? Icons.workspace_premium_rounded : Icons.group_rounded,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: aiseeTextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            value,
            style: aiseeTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: aiseeTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: StyleTokens.textSecondary,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? StyleTokens.buttonPrimary : StyleTokens.background,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: busy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: filled ? Colors.white : StyleTokens.buttonPrimary,
                  ),
                )
              : Text(
                  label,
                  style: aiseeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: filled ? Colors.white : StyleTokens.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

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
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: NetworkImage(
                  'https://api.dicebear.com/9.x/notionists/png'
                  '?seed=${Uri.encodeComponent(member.id)}'
                  '&size=96&backgroundColor=e8e8e8',
                ),
                onBackgroundImageError: (Object _, StackTrace? _) {},
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
                      AppLocalizations.of(context).familyContactsTapForInfo,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 11,
                        color: StyleTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/icons/nav/ic_arrow_right.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.textMuted,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
