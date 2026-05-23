import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../services/aisee_health_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../widgets/aisee_language_picker_sheet.dart';
import 'reminders_screen.dart';
import 'subscription_screen.dart';
import 'user_sponsor_screen.dart';

class UserPersonalTab extends StatefulWidget {
  const UserPersonalTab({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  static final GlobalKey<UserPersonalTabState> tabKey =
      GlobalKey<UserPersonalTabState>();

  @override
  State<UserPersonalTab> createState() => UserPersonalTabState();
}

class UserPersonalTabState extends State<UserPersonalTab> {
  int _medCount = 0;
  int _apptCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void refreshReminders() => _loadCounts();

  Future<void> _loadCounts() async {
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) return;
    final AiseeHealthService svc = AiseeHealthService();
    try {
      final List<Map<String, dynamic>> meds = await svc.fetchMedications(
        tokens.accessToken,
      );
      final List<Map<String, dynamic>> appts = await svc.fetchAppointments(
        tokens.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _medCount = meds.length;
        _apptCount = appts.length;
      });
    } catch (_) {}
    svc.close();
  }

  void _openScreen(ReminderFilter filter) {
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => RemindersScreen(initialFilter: filter),
          ),
        )
        .then((_) => _loadCounts());
  }

  void _openSponsors() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserSponsorScreen()));
  }

  void _openSubscription() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()));
  }

  void _openLanguagePicker() {
    HapticFeedback.lightImpact();
    AiseeLanguagePickerSheet.show(context);
  }

  String _languageSubtitle(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale current = AiseeLocaleController.instance.value;
    return current.languageCode == 'en' ? l.languageEn : l.languageVi;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l.personalTabSemanticsLabel,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Text(
            l.personalTabIntro,
            style: StyleTokens.bodySmall().copyWith(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_heart.svg',
            title: l.personalMedicationTitle,
            subtitle: _medCount > 0
                ? l.personalMedicationCount(_medCount)
                : l.personalMedicationEmpty,
            onTap: () => _openScreen(ReminderFilter.medication),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_calendar.svg',
            title: l.personalAppointmentsTitle,
            subtitle: _apptCount > 0
                ? l.personalAppointmentsCount(_apptCount)
                : l.personalAppointmentsEmpty,
            onTap: () => _openScreen(ReminderFilter.appointment),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_activity.svg',
            title: l.personalHealthLogTitle,
            subtitle: l.personalHealthLogSubtitle,
            onTap: () => _openScreen(ReminderFilter.health),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_activity.svg',
            title: l.personalSubscriptionTitle,
            subtitle: l.personalSubscriptionSubtitle,
            onTap: _openSubscription,
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: l.personalSponsorsTitle,
            subtitle: l.personalSponsorsSubtitle,
            onTap: _openSponsors,
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<Locale>(
            valueListenable: AiseeLocaleController.instance,
            builder: (BuildContext context, Locale locale, Widget? child) {
              return _MenuCard(
                iconAsset: 'assets/icons/nav/ic_activity.svg',
                title: AppLocalizations.of(context).settingsLanguageLabel,
                subtitle: _languageSubtitle(context),
                onTap: _openLanguagePicker,
              );
            },
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.personalSignOutLabel,
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
                l.personalSignOutAction,
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
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
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.familyPersonalCardActionHint(title, subtitle),
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
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
