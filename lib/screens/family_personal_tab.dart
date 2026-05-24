import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../services/aisee_family_context_store.dart';
import '../services/aisee_session_store.dart';
import '../services/aisee_volunteer_service.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../widgets/aisee_language_picker_sheet.dart';
import 'subscription_screen.dart';
import 'usage_value_screen.dart';
import 'user_sponsor_screen.dart';

class FamilyPersonalTab extends StatefulWidget {
  const FamilyPersonalTab({
    required this.profile,
    required this.onSignOut,
    super.key,
  });

  final AiseeUserProfile profile;
  final VoidCallback onSignOut;

  @override
  State<FamilyPersonalTab> createState() => _FamilyPersonalTabState();
}

class _FamilyPersonalTabState extends State<FamilyPersonalTab> {
  final AiseeVolunteerService _volunteerService = AiseeVolunteerService();
  bool _isVolunteer = false;
  bool _available = false;
  bool _volunteerStatusLoading = true;
  bool _registering = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _isVolunteer = widget.profile.isVolunteer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVolunteerStatus();
    });
  }

  /// Đồng bộ từ GET /api/v1/volunteers/status — JWT/profile có thể thiếu cờ tình nguyện viên.
  Future<void> _loadVolunteerStatus() async {
    final String? token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _volunteerStatusLoading = false;
      });
      return;
    }
    try {
      final status = await _volunteerService.fetchStatus(token);
      if (!mounted) return;
      setState(() {
        _isVolunteer = status.isRegistered;
        _available = status.available;
        _volunteerStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Chỉ tắt loading; giữ _isVolunteer/_available hiện tại (ví dụ vừa register xong).
      setState(() => _volunteerStatusLoading = false);
    }
  }

  @override
  void dispose() {
    _volunteerService.close();
    super.dispose();
  }

  Future<String?> _token() async {
    final AiseeAuthTokens? stored = await AiseeSessionStore.instance.read();
    return stored?.accessToken;
  }

  Future<void> _register() async {
    HapticFeedback.lightImpact();
    setState(() => _registering = true);
    try {
      final String? token = await _token();
      if (token == null) {
        if (!mounted) return;
        AppToast.show(
          AppLocalizations.of(context).familyPersonalSessionExpired,
          isError: true,
        );
        return;
      }
      await _volunteerService.register(token);
      if (!mounted) return;
      setState(() {
        _isVolunteer = true;
        _available = true;
      });
      await _loadVolunteerStatus();
      if (!mounted) return;
      AppToast.show(AppLocalizations.of(context).familyPersonalRegisterSuccess);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    HapticFeedback.lightImpact();
    setState(() => _toggling = true);
    try {
      final String? token = await _token();
      if (token == null) {
        if (!mounted) return;
        AppToast.show(
          AppLocalizations.of(context).familyPersonalSessionExpired,
          isError: true,
        );
        return;
      }
      await _volunteerService.setAvailability(token, available: value);
      if (!mounted) return;
      setState(() => _available = value);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  void _openSponsors() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserSponsorScreen()));
  }

  void _openLanguagePicker() {
    HapticFeedback.lightImpact();
    AiseeLanguagePickerSheet.show(context);
  }

  Future<String?> _lastCaredUserId() {
    return AiseeFamilyContextStore.instance.readLastCaredUserId();
  }

  Future<void> _openUsageValue() async {
    final String? caredUserId = await _lastCaredUserId();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UsageValueScreen(caredUserId: caredUserId),
      ),
    );
  }

  Future<void> _openSubscription() async {
    HapticFeedback.lightImpact();
    final String? caredUserId = await _lastCaredUserId();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubscriptionScreen(familyFirst: true, caredUserId: caredUserId),
      ),
    );
  }

  void _openPersonalInfo(String joinDate) {
    HapticFeedback.lightImpact();
    final AppLocalizations l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _PersonalInfoSheet(
          email: widget.profile.email,
          role: l.familyPersonalRoleSupporter,
          joinDate: joinDate,
        );
      },
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final DateTime dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String joinDate = _formatDate(widget.profile.createdAt);
    return Semantics(
      container: true,
      label: l.familyPersonalSemanticsLabel,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Text(
            l.familyPersonalIntro,
            style: StyleTokens.bodySmall().copyWith(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          _ActionCard(
            iconAsset: 'assets/icons/nav/ic_profile.svg',
            title: l.familyPersonalCardInfoTitle,
            subtitle: l.familyPersonalCardInfoSubtitle,
            onTap: () => _openPersonalInfo(joinDate),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            iconAsset: 'assets/icons/nav/ic_graph.svg',
            title: l.familyPersonalCardUsageTitle,
            subtitle: l.familyPersonalCardUsageSubtitle,
            onTap: _openUsageValue,
          ),
          const SizedBox(height: 10),
          _ActionCard(
            iconAsset: 'assets/icons/nav/ic_activity.svg',
            title: l.familyPersonalCardSubscriptionTitle,
            subtitle: l.familyPersonalCardSubscriptionSubtitle,
            onTap: _openSubscription,
          ),
          const SizedBox(height: 10),
          _VolunteerCard(
            statusLoading: _volunteerStatusLoading,
            isVolunteer: _isVolunteer,
            available: _available,
            registering: _registering,
            toggling: _toggling,
            onRegister: _register,
            onToggle: _toggleAvailability,
          ),
          const SizedBox(height: 10),
          _ActionCard(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: l.familyPersonalCardSponsorsTitle,
            subtitle: l.familyPersonalCardSponsorsSubtitle,
            onTap: _openSponsors,
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<Locale>(
            valueListenable: AiseeLocaleController.instance,
            builder: (BuildContext context, Locale locale, Widget? child) {
              final AppLocalizations l = AppLocalizations.of(context);
              return _ActionCard(
                iconAsset: 'assets/icons/nav/ic_activity.svg',
                title: l.settingsLanguageLabel,
                subtitle: locale.languageCode == 'en'
                    ? l.languageEn
                    : l.languageVi,
                onTap: _openLanguagePicker,
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(l),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(AppLocalizations l) {
    return Semantics(
      button: true,
      label: l.familyPersonalSignOutLabel,
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSignOut();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                l.familyPersonalSignOutAction,
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalInfoSheet extends StatelessWidget {
  const _PersonalInfoSheet({
    required this.email,
    required this.role,
    required this.joinDate,
  });

  final String email;
  final String role;
  final String joinDate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: StyleTokens.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: StyleTokens.cardBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.familyPersonalSheetTitle,
                  style: aiseeTextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.familyPersonalSheetClose,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: StyleTokens.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _PersonalInfoRow(
                    iconAsset: 'assets/icons/nav/ic_profile.svg',
                    title: 'Email',
                    value: email,
                  ),
                  const SizedBox(height: 14),
                  _PersonalInfoRow(
                    iconAsset: 'assets/icons/nav/ic_3user.svg',
                    title: l.familyPersonalSheetRole,
                    value: role,
                  ),
                  if (joinDate.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 14),
                    _PersonalInfoRow(
                      iconAsset: 'assets/icons/nav/ic_calendar.svg',
                      title: l.familyPersonalSheetJoinDate,
                      value: joinDate,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoRow extends StatelessWidget {
  const _PersonalInfoRow({
    required this.iconAsset,
    required this.title,
    required this.value,
  });

  final String iconAsset;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: StyleTokens.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                StyleTokens.buttonPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: aiseeTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: aiseeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.familyPersonalCardActionHint(title, subtitle),
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StyleTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: aiseeTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: aiseeTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/nav/ic_arrow_right.svg',
                  width: 8,
                  height: 8,
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
    );
  }
}

/// Volunteer card — shows registration button or availability toggle.
class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.statusLoading,
    required this.isVolunteer,
    required this.available,
    required this.registering,
    required this.toggling,
    required this.onRegister,
    required this.onToggle,
  });

  final bool statusLoading;
  final bool isVolunteer;
  final bool available;
  final bool registering;
  final bool toggling;
  final VoidCallback onRegister;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StyleTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/nav/ic_3user.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l.familyVolunteerTitle,
                        style: aiseeTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.familyVolunteerSubtitle,
                        style: aiseeTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (statusLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StyleTokens.buttonPrimary,
                    ),
                  ),
                ),
              )
            else if (!isVolunteer)
              _RegisterButton(registering: registering, onRegister: onRegister)
            else
              _AvailabilityToggle(
                available: available,
                toggling: toggling,
                onToggle: onToggle,
              ),
          ],
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.registering, required this.onRegister});

  final bool registering;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.familyVolunteerRegisterAction,
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: registering ? null : onRegister,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: registering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      l.familyVolunteerRegisterAction,
                      style: StyleTokens.socialLabel().copyWith(fontSize: 14),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({
    required this.available,
    required this.toggling,
    required this.onToggle,
  });

  final bool available;
  final bool toggling;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.familyVolunteerReadyTitle,
                style: aiseeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                available
                    ? l.familyVolunteerReadyOn
                    : l.familyVolunteerReadyOff,
                style: aiseeTextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: available,
          onChanged: toggling ? null : onToggle,
          activeThumbColor: StyleTokens.buttonPrimary,
        ),
      ],
    );
  }
}
