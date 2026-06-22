import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';

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
  static const String _welcomeImageAsset = 'assets/onboarding/welcome.jpg';
  static const String _permissionsImageAsset =
      'assets/onboarding/permissions.jpg';
  static const String _familyImageAsset = 'assets/onboarding/family.jpg';
  static const String _batteryImageAsset = 'assets/onboarding/battery.jpg';
  static const String _remindersImageAsset = 'assets/onboarding/reminders.jpg';

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
        imageAsset: _welcomeImageAsset,
      ),
      _OnboardingStep(
        title: l.onboardingPermsTitle,
        description: l.onboardingPermsDesc,
        imageAsset: _permissionsImageAsset,
      ),
      _OnboardingStep(
        title: l.onboardingFamilyTitle,
        description: l.onboardingFamilyDesc,
        imageAsset: _familyImageAsset,
      ),
      if (_showBatteryOptimizationStep)
        _OnboardingStep(
          title: l.onboardingBatteryTitle,
          description: l.onboardingBatteryDesc,
          imageAsset: _batteryImageAsset,
          isBatteryOptimization: true,
        ),
      _OnboardingStep(
        title: l.onboardingRemindersTitle,
        description: l.onboardingRemindersDesc,
        imageAsset: _remindersImageAsset,
        isRoleSelection: true,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage =>
      _pageIndex == _stepsLength(AppLocalizations.of(context)) - 1;

  int _stepsLength(AppLocalizations l) => _buildSteps(l).length;

  int _skipTargetIndex(List<_OnboardingStep> steps) => steps.length - 1;

  Future<void> _goNext() async {
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
    final bool canContinue = currentStep.isBatteryOptimization
        ? _batteryGranted
        : !isLast || (isLast && _selectedRole != null);
    final bool canSkip = !isLast && !currentStep.isBatteryOptimization;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            physics: null,
            itemCount: steps.length,
            clipBehavior: Clip.hardEdge,
            onPageChanged: (int index) {
              setState(() => _pageIndex = index);
            },
            itemBuilder: (BuildContext context, int index) {
              return _OnboardingStepView(
                step: steps[index],
                selectedRole: _selectedRole,
                onSelectRole: (String role) {
                  setState(() => _selectedRole = role);
                },
                batteryOptimizationController: _batteryOptimizationController,
                onBatteryStatusChanged: (bool granted) {
                  if (_batteryGranted == granted) return;
                  setState(() => _batteryGranted = granted);
                },
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'AiSee',
                    style: StyleTokens.socialLabel().copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 0,
                    ),
                  ),
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
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.transparent,
                      ),
                      child: Text(
                        l.onboardingSkip,
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: canSkip
                              ? Colors.white.withValues(alpha: 0.84)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: steps.length,
                        effect: WormEffect(
                          dotHeight: 9,
                          dotWidth: 9,
                          spacing: 9,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withValues(alpha: 0.34),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: canContinue ? _goNext : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: StyleTokens.buttonPrimary,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.34,
                        ),
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
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 18,
                      child: AnimatedOpacity(
                        opacity:
                            currentStep.isRoleSelection && _selectedRole == null
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          l.onboardingChooseRoleHint,
                          style: StyleTokens.legalMuted().copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                            letterSpacing: 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _OnboardingBackgroundImage(asset: step.imageAsset),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.38),
                Colors.black.withValues(alpha: 0.04),
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.78),
              ],
              stops: const <double>[0, 0.36, 0.58, 1],
            ),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double contentTop = step.isBatteryOptimization
                  ? constraints.maxHeight * 0.38
                  : step.isRoleSelection
                  ? constraints.maxHeight * 0.34
                  : constraints.maxHeight * 0.58;
              final double contentBottom = step.isRoleSelection ? 132 : 154;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, contentTop, 22, contentBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: StyleTokens.titleScreen().copyWith(
                        fontSize: 38,
                        height: 1.05,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      step.description,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.84),
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (step.isBatteryOptimization) ...<Widget>[
                      const SizedBox(height: 22),
                      _BatteryOptimizationCard(
                        accent: StyleTokens.buttonPrimary,
                        controller: batteryOptimizationController,
                        onStatusChanged: onBatteryStatusChanged,
                      ),
                    ],
                    if (step.isRoleSelection) ...<Widget>[
                      const SizedBox(height: 24),
                      _RoleChoiceCard(
                        title: AppLocalizations.of(
                          context,
                        ).onboardingRoleUserTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        ).onboardingRoleUserSubtitle,
                        value: 'user',
                        selectedValue: selectedRole,
                        onSelect: onSelectRole,
                      ),
                      const SizedBox(height: 12),
                      _RoleChoiceCard(
                        title: AppLocalizations.of(
                          context,
                        ).onboardingRoleFamilyTitle,
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
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OnboardingBackgroundImage extends StatelessWidget {
  const _OnboardingBackgroundImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, fit: BoxFit.cover, alignment: Alignment.center);
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
      color: StyleTokens.surfaceCard.withValues(alpha: selected ? 0.96 : 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? StyleTokens.buttonPrimary.withValues(alpha: 0.04)
                : Colors.transparent,
            border: Border.all(
              color: selected
                  ? StyleTokens.buttonPrimary
                  : StyleTokens.cardBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill)
                    : PhosphorIcons.circle(PhosphorIconsStyle.regular),
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
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 13,
                        color: StyleTokens.textSecondary,
                        letterSpacing: 0,
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
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.batteryWarning(
                          PhosphorIconsStyle.duotone,
                        ),
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
                  : Icon(
                      PhosphorIcons.power(PhosphorIconsStyle.bold),
                      size: 18,
                    ),
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
      bg = StyleTokens.buttonPrimary.withValues(alpha: 0.10);
      fg = StyleTokens.buttonPrimary;
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
    required this.imageAsset,
    this.isRoleSelection = false,
    this.isBatteryOptimization = false,
  });

  final String title;
  final String description;
  final String imageAsset;
  final bool isRoleSelection;
  final bool isBatteryOptimization;
}
