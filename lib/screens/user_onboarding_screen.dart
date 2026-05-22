import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';

abstract class BatteryOptimizationController {
  Future<bool> isGranted();

  Future<bool> request();

  Future<void> openSettings();
}

class PermissionHandlerBatteryOptimizationController
    implements BatteryOptimizationController {
  const PermissionHandlerBatteryOptimizationController();

  @override
  Future<bool> isGranted() async {
    final PermissionStatus status =
        await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  @override
  Future<void> openSettings() {
    return openAppSettings();
  }

  @override
  Future<bool> request() async {
    final PermissionStatus status = await Permission.ignoreBatteryOptimizations
        .request();
    return status.isGranted;
  }
}

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({
    super.key,
    required this.onCompleted,
    this.batteryOptimizationController,
    this.showBatteryOptimizationStep,
  });

  final void Function(String role) onCompleted;
  final BatteryOptimizationController? batteryOptimizationController;
  final bool? showBatteryOptimizationStep;

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  static const String? _welcomeLottieAsset = null;
  static const String? _permissionsLottieAsset = null;
  static const String? _familyLottieAsset = null;
  static const String? _remindersLottieAsset = null;
  static const String? _batteryLottieAsset = null;

  late final PageController _pageController;
  int _pageIndex = 0;
  String? _selectedRole;
  bool _batteryGranted = false;

  BatteryOptimizationController get _batteryOptimizationController =>
      widget.batteryOptimizationController ??
      const PermissionHandlerBatteryOptimizationController();

  bool get _showBatteryOptimizationStep =>
      widget.showBatteryOptimizationStep ?? (!kIsWeb && Platform.isAndroid);

  List<_OnboardingStep> _buildSteps(AppLocalizations l) {
    return <_OnboardingStep>[
      _OnboardingStep(
        title: l.onboardingWelcomeTitle,
        description: l.onboardingWelcomeDesc,
        highlights: <String>[
          l.onboardingWelcomeBullet1,
          l.onboardingWelcomeBullet2,
          l.onboardingWelcomeBullet3,
        ],
        icon: Icons.record_voice_over_rounded,
        accentColor: const Color(0xFFE4A66A),
        lottieAssetPath: _welcomeLottieAsset,
      ),
      _OnboardingStep(
        title: l.onboardingPermsTitle,
        description: l.onboardingPermsDesc,
        highlights: <String>[
          l.onboardingPermsBullet1,
          l.onboardingPermsBullet2,
          l.onboardingPermsBullet3,
        ],
        icon: Icons.mic_external_on_rounded,
        accentColor: const Color(0xFF7FB8A4),
        lottieAssetPath: _permissionsLottieAsset,
      ),
      _OnboardingStep(
        title: l.onboardingFamilyTitle,
        description: l.onboardingFamilyDesc,
        highlights: <String>[
          l.onboardingFamilyBullet1,
          l.onboardingFamilyBullet2,
          l.onboardingFamilyBullet3,
        ],
        icon: Icons.family_restroom_rounded,
        accentColor: const Color(0xFFF0B7A3),
        lottieAssetPath: _familyLottieAsset,
      ),
      if (_showBatteryOptimizationStep)
        _OnboardingStep(
          title: l.onboardingBatteryTitle,
          description: l.onboardingBatteryDesc,
          highlights: <String>[
            l.onboardingBatteryBullet1,
            l.onboardingBatteryBullet2,
            l.onboardingBatteryBullet3,
          ],
          icon: Icons.battery_charging_full_rounded,
          accentColor: const Color(0xFF8FB8E4),
          lottieAssetPath: _batteryLottieAsset,
          isBatteryOptimization: true,
        ),
      _OnboardingStep(
        title: l.onboardingRemindersTitle,
        description: l.onboardingRemindersDesc,
        highlights: <String>[
          l.onboardingRemindersBullet1,
          l.onboardingRemindersBullet2,
          l.onboardingRemindersBullet3,
        ],
        icon: Icons.notifications_active_rounded,
        accentColor: const Color(0xFFF3D27A),
        lottieAssetPath: _remindersLottieAsset,
        isRoleSelection: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.94);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage =>
      _pageIndex == _stepsLength(AppLocalizations.of(context)) - 1;

  int _stepsLength(AppLocalizations l) => _buildSteps(l).length;

  bool _currentStepRequiresBatteryGrant(List<_OnboardingStep> steps) =>
      steps[_pageIndex].isBatteryOptimization && !_batteryGranted;

  int _batteryStepIndex(List<_OnboardingStep> steps) =>
      steps.indexWhere((_OnboardingStep step) => step.isBatteryOptimization);

  int _skipTargetIndex(List<_OnboardingStep> steps) {
    final int batteryIndex = _batteryStepIndex(steps);
    if (batteryIndex != -1 && !_batteryGranted && _pageIndex < batteryIndex) {
      return batteryIndex;
    }
    return steps.length - 1;
  }

  Future<void> _goNext() async {
    final List<_OnboardingStep> steps = _buildSteps(
      AppLocalizations.of(context),
    );
    if (_currentStepRequiresBatteryGrant(steps)) {
      return;
    }
    if (_isLastPage) {
      final String? role = _selectedRole;
      if (role == null) {
        return;
      }
      widget.onCompleted(role);
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<_OnboardingStep> steps = _buildSteps(l);
    final _OnboardingStep currentStep = steps[_pageIndex];
    final bool isLast = _pageIndex == steps.length - 1;
    final bool batteryRequired = _currentStepRequiresBatteryGrant(steps);
    final bool canContinue =
        (!isLast && !batteryRequired) || (isLast && _selectedRole != null);
    final bool canSkip = !isLast && !currentStep.isBatteryOptimization;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const AppWordmark(fontSize: 18),
                  const Spacer(),
                  SizedBox(
                    width: 76,
                    child: TextButton(
                      onPressed: canSkip
                          ? () {
                              _pageController.animateToPage(
                                _skipTargetIndex(steps),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: StyleTokens.textSecondary,
                        disabledForegroundColor: Colors.transparent,
                      ),
                      child: Text(
                        l.onboardingSkip,
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: canSkip
                              ? StyleTokens.textSecondary
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: batteryRequired
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: steps.length,
                  padEnds: false,
                  clipBehavior: Clip.hardEdge,
                  onPageChanged: (int index) {
                    setState(() => _pageIndex = index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == steps.length - 1 ? 0 : 10,
                      ),
                      child: _OnboardingStepView(
                        step: steps[index],
                        selectedRole: _selectedRole,
                        onSelectRole: (String role) {
                          setState(() => _selectedRole = role);
                        },
                        batteryOptimizationController:
                            _batteryOptimizationController,
                        onBatteryStatusChanged: (bool granted) {
                          if (_batteryGranted == granted) return;
                          setState(() => _batteryGranted = granted);
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: steps.length,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 10,
                    activeDotColor: StyleTokens.buttonPrimary,
                    dotColor: StyleTokens.cardBorder,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: canContinue ? _goNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: StyleTokens.buttonPrimary,
                  disabledBackgroundColor: StyleTokens.cardBorder,
                  foregroundColor: StyleTokens.buttonOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  isLast ? l.onboardingFinish : l.onboardingNext,
                  style: StyleTokens.socialLabel().copyWith(
                    fontSize: 15,
                    color: canContinue
                        ? StyleTokens.buttonOnPrimary
                        : StyleTokens.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 18,
                child: AnimatedOpacity(
                  opacity: currentStep.isRoleSelection && _selectedRole == null
                      ? 1
                      : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    l.onboardingChooseRoleHint,
                    style: StyleTokens.legalMuted(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({
    required this.step,
    required this.selectedRole,
    required this.onSelectRole,
    required this.batteryOptimizationController,
    required this.onBatteryStatusChanged,
  });

  final _OnboardingStep step;
  final String? selectedRole;
  final ValueChanged<String> onSelectRole;
  final BatteryOptimizationController batteryOptimizationController;
  final ValueChanged<bool> onBatteryStatusChanged;

  @override
  Widget build(BuildContext context) {
    final Widget highlightsCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: step.highlights
            .map(
              (String item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: step.accentColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: StyleTokens.buttonPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );

    return ColoredBox(
      color: StyleTokens.background,
      child: ClipRect(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _OnboardingHero(step: step),
              const SizedBox(height: 28),
              Text(
                step.title,
                style: StyleTokens.titleScreen().copyWith(
                  fontSize: 28,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              if (step.isBatteryOptimization) ...<Widget>[
                const SizedBox(height: 18),
                _BatteryOptimizationCard(
                  accent: step.accentColor,
                  controller: batteryOptimizationController,
                  onStatusChanged: onBatteryStatusChanged,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                step.description,
                style: StyleTokens.bodySmall().copyWith(
                  fontSize: 15,
                  height: 1.55,
                  color: StyleTokens.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!step.isBatteryOptimization) highlightsCard,
              if (step.isBatteryOptimization) ...<Widget>[highlightsCard],
              if (step.isRoleSelection) ...<Widget>[
                const SizedBox(height: 18),
                _RoleChoiceCard(
                  title: AppLocalizations.of(context).onboardingRoleUserTitle,
                  subtitle: AppLocalizations.of(
                    context,
                  ).onboardingRoleUserSubtitle,
                  value: 'user',
                  selectedValue: selectedRole,
                  onSelect: onSelectRole,
                ),
                const SizedBox(height: 12),
                _RoleChoiceCard(
                  title: AppLocalizations.of(context).onboardingRoleFamilyTitle,
                  subtitle: AppLocalizations.of(
                    context,
                  ).onboardingRoleFamilySubtitle,
                  value: 'family',
                  selectedValue: selectedRole,
                  onSelect: onSelectRole,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.selectedValue,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final String value;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool selected = selectedValue == value;
    return Material(
      color: selected
          ? StyleTokens.buttonPrimary.withValues(alpha: 0.08)
          : StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? StyleTokens.buttonPrimary
                  : StyleTokens.cardBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? StyleTokens.buttonPrimary
                    : StyleTokens.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StyleTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 13,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            step.accentColor.withValues(alpha: 0.25),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: 16,
            right: 18,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: step.accentColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(27),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: step.accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Center(
            child: step.lottieAssetPath == null
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.98, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder:
                        (BuildContext context, double value, Widget? child) {
                          return Transform.scale(scale: value, child: child);
                        },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: step.accentColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        size: 30,
                        color: StyleTokens.buttonPrimary,
                      ),
                    ),
                  )
                : Lottie.asset(
                    step.lottieAssetPath!,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _BatteryOptimizationCard extends StatefulWidget {
  const _BatteryOptimizationCard({
    required this.accent,
    required this.controller,
    required this.onStatusChanged,
  });

  final Color accent;
  final BatteryOptimizationController controller;
  final ValueChanged<bool> onStatusChanged;

  @override
  State<_BatteryOptimizationCard> createState() =>
      _BatteryOptimizationCardState();
}

class _BatteryOptimizationCardState extends State<_BatteryOptimizationCard>
    with WidgetsBindingObserver {
  bool _granted = false;
  bool _checking = true;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final bool granted = await widget.controller.isGranted();
      if (!mounted) return;
      setState(() {
        _granted = granted;
        _checking = false;
      });
      widget.onStatusChanged(granted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      widget.onStatusChanged(false);
    }
  }

  Future<void> _request() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final bool granted = await widget.controller.request();
      if (!mounted) return;
      setState(() => _granted = granted);
      widget.onStatusChanged(granted);
    } catch (_) {
      // Một số OEM (Xiaomi/Oppo) không cho cấp ở dialog → mở settings.
      try {
        await widget.controller.openSettings();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.accent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _granted
                      ? Icons.check_circle_rounded
                      : Icons.battery_saver_rounded,
                  size: 20,
                  color: _granted
                      ? const Color(0xFF2E8B57)
                      : StyleTokens.buttonPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _checking
                      ? AppLocalizations.of(context).onboardingBatteryChecking
                      : _granted
                      ? AppLocalizations.of(context).onboardingBatteryGranted
                      : AppLocalizations.of(
                          context,
                        ).onboardingBatteryNotGranted,
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ),
              _StatusPill(granted: _granted, loading: _checking),
            ],
          ),
          const SizedBox(height: 14),
          if (!_granted) ...<Widget>[
            FilledButton.icon(
              onPressed: _requesting ? null : _request,
              style: FilledButton.styleFrom(
                backgroundColor: StyleTokens.buttonPrimary,
                disabledBackgroundColor: StyleTokens.cardBorder,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: _requesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.power_settings_new_rounded, size: 18),
              label: Text(
                AppLocalizations.of(context).onboardingBatteryButton,
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => widget.controller.openSettings(),
              style: TextButton.styleFrom(
                foregroundColor: StyleTokens.textSecondary,
              ),
              child: Text(
                AppLocalizations.of(context).onboardingBatteryOpenSettings,
                style: StyleTokens.bodySmall().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ] else
            Text(
              AppLocalizations.of(context).onboardingBatteryDoneNote,
              style: StyleTokens.bodySmall().copyWith(
                fontSize: 13,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.granted, required this.loading});

  final bool granted;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    if (loading) {
      bg = StyleTokens.background;
      fg = StyleTokens.textSecondary;
      label = '…';
    } else if (granted) {
      bg = const Color(0xFFE3F4EA);
      fg = const Color(0xFF2E8B57);
      label = AppLocalizations.of(context).onboardingStatusOn;
    } else {
      bg = const Color(0xFFFFF1E0);
      fg = const Color(0xFFB8651D);
      label = AppLocalizations.of(context).onboardingStatusOff;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: StyleTokens.bodySmall().copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _OnboardingStep {
  _OnboardingStep({
    required this.title,
    required this.description,
    required this.highlights,
    required this.icon,
    required this.accentColor,
    required this.lottieAssetPath,
    this.isRoleSelection = false,
    this.isBatteryOptimization = false,
  });

  final String title;
  final String description;
  final List<String> highlights;
  final IconData icon;
  final Color accentColor;
  final String? lottieAssetPath;
  final bool isRoleSelection;
  final bool isBatteryOptimization;
}
