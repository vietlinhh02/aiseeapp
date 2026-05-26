import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';
import '../models/aisee_family_group.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_billing_service.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_profile_cache.dart';
import '../services/aisee_revenuecat_service.dart';
import '../services/aisee_token_provider.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../widgets/app_wordmark.dart';
import '../generated/l10n/app_localizations.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.familyFirst = false,
    this.careGroupId,
    this.caredUserId,
    this.billingService,
    this.familyService,
    this.readTokens,
  });

  final bool familyFirst;
  final String? careGroupId;
  final String? caredUserId;
  final AiseeBillingService? billingService;
  final AiseeFamilyService? familyService;
  final Future<AiseeAuthTokens?> Function()? readTokens;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final AiseeBillingService _billingService;
  late final AiseeFamilyService _familyService;
  late final Future<AiseeAuthTokens?> Function() _readTokens;
  late final bool _ownsBillingService;
  late final bool _ownsFamilyService;
  AiseeBillingOverview? _overview;
  bool _loading = true;
  bool _revenueCatBusy = false;
  String? _error;
  bool get _revenueCatEnabled => AiseeRevenueCatService.instance.isEnabled;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _billingService = widget.billingService ?? AiseeBillingService();
    _familyService = widget.familyService ?? AiseeFamilyService();
    _readTokens = widget.readTokens ?? AiseeTokenProvider.instance.tokens;
    _ownsBillingService = widget.billingService == null;
    _ownsFamilyService = widget.familyService == null;
    unawaited(AiseeAnalyticsService.instance.trackScreen('subscription'));
    unawaited(
      AiseeAnalyticsService.instance.track(AiseeAnalyticsEvent.pricingViewed),
    );
    _load();
  }

  @override
  void dispose() {
    if (_ownsBillingService) {
      _billingService.close();
    }
    if (_ownsFamilyService) {
      _familyService.close();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AiseeAuthTokens? tokens = await _readTokens();
      if (tokens == null) {
        throw AiseeApiException(l10n.subscriptionSessionExpired);
      }
      final _BillingScreenContext billingContext = await _resolveBillingContext(
        tokens.accessToken,
      );
      final AiseeBillingOverview overview = await _billingService
          .fetchBillingOverview(
            tokens.accessToken,
            careGroupId: billingContext.careGroupId,
            caredUserId: billingContext.caredUserId,
          );
      if (overview.subscription?.cancelAtPeriodEnd ?? false) {
        unawaited(
          AiseeAnalyticsService.instance.trackOnce(
            AiseeAnalyticsEvent.subscriptionCancelled,
            key: 'subscription_cancelled.${overview.subscription?.id}',
            parameters: <String, Object?>{
              'plan_code': overview.effectivePlan.code,
              'care_group_id': overview.careGroup.id,
            },
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _overview = overview;
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

  Future<_BillingScreenContext> _resolveBillingContext(
    String accessToken,
  ) async {
    if (widget.careGroupId != null || widget.caredUserId != null) {
      return _BillingScreenContext(
        careGroupId: widget.careGroupId,
        caredUserId: widget.caredUserId,
      );
    }
    final AiseeCurrentGroup? currentGroup = await _familyService
        .fetchCurrentGroup(accessToken);
    if (currentGroup == null) {
      return const _BillingScreenContext();
    }
    return _BillingScreenContext(careGroupId: currentGroup.id);
  }

  Future<void> _openStoreManagement(AiseeBillingOverview overview) async {
    if (!_revenueCatEnabled) {
      AppToast.show(l10n.subscriptionTemporaryUnavailable);
      return;
    }
    if (!canManageSubscriptionForGroup(
      overview,
      familyFirst: widget.familyFirst,
    )) {
      AppToast.show(l10n.subscriptionOnlyGroupOwner);
      return;
    }
    HapticFeedback.lightImpact();
    final String? url = overview.storeManagement.manageUrl;
    if (url == null || url.isEmpty) {
      AppToast.show(overview.storeManagement.instructions);
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppToast.show(l10n.subscriptionCannotOpenManagement, isError: true);
    }
  }

  Future<void> _startUpgrade(AiseeBillingOverview overview) async {
    if (!_revenueCatEnabled) {
      AppToast.show(l10n.subscriptionTemporaryUnavailable);
      return;
    }
    HapticFeedback.mediumImpact();
    await AiseeAnalyticsService.instance.track(
      AiseeAnalyticsEvent.upgradeClicked,
      parameters: <String, Object?>{
        'plan_code': overview.effectivePlan.code,
        'care_group_id': overview.careGroup.id,
      },
    );
    if (!canManageSubscriptionForGroup(
      overview,
      familyFirst: widget.familyFirst,
    )) {
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.featureGateSeen,
          parameters: <String, Object?>{
            'feature': 'billing_management',
            'plan_code': overview.effectivePlan.code,
            'care_group_id': overview.careGroup.id,
          },
        ),
      );
      AppToast.show(l10n.subscriptionOnlyGroupOwnerPurchase);
      return;
    }
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show(l10n.subscriptionSessionExpired, isError: true);
      return;
    }
    setState(() => _revenueCatBusy = true);
    try {
      final Future<List<AiseeRevenueCatPackageOption>> optionsFuture =
          () async {
            await AiseeRevenueCatService.instance.identify(
              profile,
              careGroupId: overview.careGroup.id,
            );
            return AiseeRevenueCatService.instance.availablePackageOptions();
          }();
      await _showPlanPicker(overview, optionsFuture);
    } on AiseeRevenueCatException catch (e) {
      if (!mounted || e.cancelled) return;
      AppToast.show(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _revenueCatBusy = false);
    }
  }

  Future<void> _showPlanPicker(
    AiseeBillingOverview overview,
    Future<List<AiseeRevenueCatPackageOption>> optionsFuture,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return _PlanPickerSheet(
          overview: overview,
          optionsFuture: optionsFuture,
          onPurchased: _handlePurchasedPackage,
        );
      },
    );
  }

  Future<void> _handlePurchasedPackage(
    AiseeRevenueCatPackageOption option,
  ) async {
    AppToast.show(l10n.subscriptionPaymentSuccess);
    final bool synced = await _waitForBillingSync(option.product);
    if (!mounted) return;
    if (synced) {
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.subscriptionStarted,
          parameters: <String, Object?>{
            'plan_code': _planCodeForProduct(option.product),
            'product_id': option.storeProductIdentifier,
          },
        ),
      );
      AppToast.show(
        l10n.subscriptionPlanUpdated(planNameForProduct(option.product)),
      );
    } else {
      AppToast.show(l10n.subscriptionSyncInProgress);
    }
  }

  Future<bool> _waitForBillingSync(AiseeRevenueCatProduct product) async {
    final AiseeAuthTokens? tokens = await _readTokens();
    if (tokens == null) return false;
    final _BillingScreenContext billingContext = await _resolveBillingContext(
      tokens.accessToken,
    );
    final String expectedPlanCode = _planCodeForProduct(product);
    for (int attempt = 0; attempt < 15; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      try {
        final AiseeBillingOverview next = await _billingService
            .fetchBillingOverview(
              tokens.accessToken,
              careGroupId: billingContext.careGroupId,
              caredUserId: billingContext.caredUserId,
            );
        if (!mounted) return false;
        setState(() => _overview = next);
        if (next.effectivePlan.code == expectedPlanCode &&
            next.subscription?.status == 'active') {
          return true;
        }
      } catch (_) {
        // Retry while RevenueCat webhook delivery is still settling.
      }
    }
    return false;
  }

  Future<void> _restorePurchases(AiseeBillingOverview overview) async {
    HapticFeedback.lightImpact();
    if (!_revenueCatEnabled) {
      AppToast.show(l10n.subscriptionTemporaryUnavailable);
      return;
    }
    if (!canManageSubscriptionForGroup(
      overview,
      familyFirst: widget.familyFirst,
    )) {
      AppToast.show(l10n.subscriptionOnlyGroupOwner);
      return;
    }
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show(l10n.subscriptionSessionExpired, isError: true);
      return;
    }
    setState(() => _revenueCatBusy = true);
    try {
      await AiseeRevenueCatService.instance.identify(
        profile,
        careGroupId: overview.careGroup.id,
      );
      final customerInfo = await AiseeRevenueCatService.instance
          .refreshPurchasesForCurrentPlatform();
      if (!mounted) return;
      if (AiseeRevenueCatService.hasAiSeePro(customerInfo)) {
        AppToast.show(l10n.subscriptionProSynced);
        final bool synced = await _waitForBillingSync(
          _recommendedRestoreProduct(overview),
        );
        if (!mounted) return;
        if (!synced) {
          await _load();
          AppToast.show(l10n.subscriptionStoreEntitlement);
        }
      } else {
        AppToast.show(l10n.subscriptionNoProFound);
      }
    } on AiseeRevenueCatException catch (e) {
      if (!mounted || e.cancelled) return;
      AppToast.show(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _revenueCatBusy = false);
    }
  }

  Future<void> _openCustomerCenter(AiseeBillingOverview overview) async {
    HapticFeedback.lightImpact();
    if (!_revenueCatEnabled) {
      AppToast.show(l10n.subscriptionTemporaryUnavailable);
      return;
    }
    if (!canManageSubscriptionForGroup(
      overview,
      familyFirst: widget.familyFirst,
    )) {
      AppToast.show(l10n.subscriptionOnlyGroupOwner);
      return;
    }
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show(l10n.subscriptionSessionExpired, isError: true);
      return;
    }
    setState(() => _revenueCatBusy = true);
    try {
      await AiseeRevenueCatService.instance.identify(
        profile,
        careGroupId: overview.careGroup.id,
      );
      await AiseeRevenueCatService.instance.presentCustomerCenter();
      if (mounted) await _load();
    } on AiseeRevenueCatException catch (e) {
      if (!mounted || e.cancelled) return;
      AppToast.show(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _revenueCatBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                l10n.subscriptionTitle,
                style: aiseeTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ),
            const AppWordmark(fontSize: 15),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: StyleTokens.bodySmall(),
              ),
              const SizedBox(height: 16),
              _PrimaryButton(label: l10n.subscriptionRetry, onTap: _load),
            ],
          ),
        ),
      );
    }
    final AiseeBillingOverview overview = _overview!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: <Widget>[
          _CurrentPlanCard(
            overview: overview,
            familyFirst: widget.familyFirst,
            revenueCatEnabled: _revenueCatEnabled,
            onUpgrade: () => _startUpgrade(overview),
          ),
          if (!_revenueCatEnabled) ...<Widget>[
            const SizedBox(height: 12),
            const _RevenueCatDisabledCard(),
          ],
          if (_shouldSuggestUpgrade(overview)) ...<Widget>[
            const SizedBox(height: 12),
            _UpgradeHintCard(onTap: () => _startUpgrade(overview)),
          ],
          const SizedBox(height: 12),
          _QuotaCard(quotas: overview.usage.quotas.values.toList()),
          const SizedBox(height: 12),
          _EntitlementsCard(overview: overview, showEnabled: true),
          const SizedBox(height: 12),
          _EntitlementsCard(overview: overview, showEnabled: false),
          const SizedBox(height: 12),
          _HistoryCard(events: overview.events),
          const SizedBox(height: 12),
          _InvoicePlaceholderCard(
            overview: overview,
            revenueCatEnabled: _revenueCatEnabled,
          ),
          const SizedBox(height: 12),
          _StoreCard(
            overview: overview,
            revenueCatEnabled: _revenueCatEnabled,
            canManageStore: canShowRevenueCatStoreActions(
              overview,
              familyFirst: widget.familyFirst,
              revenueCatEnabled: _revenueCatEnabled,
            ),
            onManage: () => _openStoreManagement(overview),
            onCustomerCenter: () => _openCustomerCenter(overview),
            onRestore: () => _restorePurchases(overview),
          ),
        ],
      ),
    );
  }

  bool _shouldSuggestUpgrade(AiseeBillingOverview overview) {
    if (!_revenueCatEnabled) {
      return false;
    }
    if (!canManageSubscriptionForGroup(
      overview,
      familyFirst: widget.familyFirst,
    )) {
      return false;
    }
    if (!hasAvailableSubscriptionUpgrade(overview)) {
      return false;
    }
    if (overview.effectivePlan.isFree) return true;
    return overview.usage.quotas.values.any((quota) => quota.upgradeSuggested);
  }
}

AiseeRevenueCatPackageOption? _recommendedOption(
  AiseeBillingOverview overview,
  List<AiseeRevenueCatPackageOption> options,
) {
  final List<AiseeRevenueCatPackageOption> upgradable =
      options
          .where(
            (AiseeRevenueCatPackageOption option) =>
                canUpgradeToSubscriptionProduct(overview, option.product),
          )
          .toList()
        ..sort(
          (AiseeRevenueCatPackageOption a, AiseeRevenueCatPackageOption b) =>
              _subscriptionPlanRankForProduct(
                a.product,
              ).compareTo(_subscriptionPlanRankForProduct(b.product)),
        );
  if (upgradable.isEmpty) {
    return null;
  }
  final int currentRank = subscriptionPlanRankForCode(
    _currentPlanCode(overview),
  );
  for (final AiseeRevenueCatPackageOption option in upgradable) {
    if (_subscriptionPlanRankForProduct(option.product) == currentRank + 1) {
      return option;
    }
  }
  return upgradable.first;
}

String _currentPlanCode(AiseeBillingOverview overview) {
  return overview.subscription?.planCode ?? overview.effectivePlan.code;
}

bool _isDefaultPlusTrial(AiseeBillingOverview overview) {
  return overview.effectivePlan.code == 'plus_399k' &&
      ((overview.subscription?.status == 'trialing') ||
          overview.effectivePlan.name == 'Trial 1 tháng' ||
          overview.effectivePlan.name == 'AiSee Plus Trial');
}

String _displayedPlanName(AiseeBillingOverview overview) {
  if (_isDefaultPlusTrial(overview)) {
    return 'AiSee Plus Trial';
  }
  return overview.effectivePlan.name;
}

String _displayedPlanPrice(
  AiseeBillingOverview overview,
  AppLocalizations l10n,
) {
  if (_isDefaultPlusTrial(overview)) {
    return l10n.subscriptionFreeTrial;
  }
  return _formatPrice(overview.effectivePlan, l10n);
}

bool hasAvailableSubscriptionUpgrade(AiseeBillingOverview overview) {
  return subscriptionPlanRankForCode(_currentPlanCode(overview)) <
      subscriptionPlanRankForCode('premium_599k');
}

int subscriptionPlanRankForCode(String? planCode) {
  switch ((planCode ?? '').trim().toLowerCase()) {
    case 'basic_149k':
      return 1;
    case 'plus_399k':
      return 2;
    case 'premium_599k':
      return 3;
    default:
      return 0;
  }
}

int _subscriptionPlanRankForProduct(AiseeRevenueCatProduct product) {
  return subscriptionPlanRankForCode(_planCodeForProduct(product));
}

bool canUpgradeToSubscriptionProduct(
  AiseeBillingOverview overview,
  AiseeRevenueCatProduct product,
) {
  return _subscriptionPlanRankForProduct(product) >
      subscriptionPlanRankForCode(_currentPlanCode(overview));
}

String? _planOptionHintLocalized(
  AiseeBillingOverview overview,
  AiseeRevenueCatProduct product,
  AppLocalizations l10n,
) {
  if (_isCurrentPlan(overview, product)) {
    return l10n.subscriptionUsing;
  }
  if (!canUpgradeToSubscriptionProduct(overview, product)) {
    return l10n.subscriptionNoDowngrade;
  }
  return null;
}

String _planPickerActionLabel(
  AiseeBillingOverview overview,
  AiseeRevenueCatPackageOption? selected, {
  required bool buying,
  required String processingLabel,
  required String chooseToContinueLabel,
  required String alreadyHighestLabel,
  required String alreadyUsingLabel,
  required String upgradeOnlyLabel,
  required String continueWithTemplate,
}) {
  if (buying) {
    return processingLabel;
  }
  if (selected == null) {
    return hasAvailableSubscriptionUpgrade(overview)
        ? chooseToContinueLabel
        : alreadyHighestLabel;
  }
  if (!canUpgradeToSubscriptionProduct(overview, selected.product)) {
    return _isCurrentPlan(overview, selected.product)
        ? alreadyUsingLabel
        : upgradeOnlyLabel;
  }
  return continueWithTemplate.replaceAll(
    '{plan}',
    planNameForProduct(selected.product),
  );
}

bool _canSubmitSelectedPlan(
  AiseeBillingOverview overview,
  AiseeRevenueCatPackageOption? selected, {
  required bool buying,
}) {
  return !buying &&
      selected != null &&
      canUpgradeToSubscriptionProduct(overview, selected.product);
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.overview,
    required this.familyFirst,
    required this.revenueCatEnabled,
    required this.onUpgrade,
  });

  final AiseeBillingOverview overview;
  final bool familyFirst;
  final bool revenueCatEnabled;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AiseeSubscription? subscription = overview.subscription;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.workspace_premium,
            title: l10n.subscriptionCurrentPlan,
            trailing: _StatusPill(
              label: subscription?.status ?? 'free',
              positive:
                  subscription?.status == 'active' ||
                  subscription?.status == 'trialing' ||
                  overview.effectivePlan.isFree,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _displayedPlanName(overview),
            style: aiseeTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displayedPlanPrice(overview, l10n),
            style: StyleTokens.bodySmall().copyWith(
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.subscriptionGroupInfo(
              overview.careGroup.name,
              overview.careGroup.caredUserCount,
              overview.careGroup.memberCount,
            ),
            style: StyleTokens.bodySmall().copyWith(fontSize: 12),
          ),
          if (subscription?.cancelAtPeriodEnd ?? false) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              subscription?.currentPeriodEnd != null
                  ? l10n.subscriptionRenewalOffEndDate(
                      _formatDate(subscription!.currentPeriodEnd!),
                    )
                  : l10n.subscriptionRenewalOff,
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textSecondary,
              ),
            ),
          ],
          if (canShowSubscriptionPurchaseCta(
            overview,
            familyFirst: familyFirst,
            revenueCatEnabled: revenueCatEnabled,
          )) ...<Widget>[
            const SizedBox(height: 16),
            _PrimaryButton(
              label: overview.effectivePlan.isFree
                  ? l10n.subscriptionViewPlansToBuy
                  : l10n.subscriptionViewSuitablePlans,
              onTap: onUpgrade,
            ),
          ],
        ],
      ),
    );
  }
}

bool canManageSubscriptionForGroup(
  AiseeBillingOverview overview, {
  required bool familyFirst,
}) {
  return familyFirst && overview.careGroup.currentUserRole == 'owner';
}

bool canShowSubscriptionPurchaseCta(
  AiseeBillingOverview overview, {
  required bool familyFirst,
  bool revenueCatEnabled = true,
}) {
  return revenueCatEnabled &&
      canManageSubscriptionForGroup(overview, familyFirst: familyFirst) &&
      hasAvailableSubscriptionUpgrade(overview);
}

bool canShowRevenueCatStoreActions(
  AiseeBillingOverview overview, {
  required bool familyFirst,
  bool revenueCatEnabled = true,
}) {
  return revenueCatEnabled &&
      canManageSubscriptionForGroup(overview, familyFirst: familyFirst);
}

AiseeRevenueCatProduct _recommendedRestoreProduct(
  AiseeBillingOverview overview,
) {
  final String activePlanCode = _currentPlanCode(overview);
  switch (activePlanCode) {
    case 'premium_599k':
      return AiseeRevenueCatProduct.premium599k;
    case 'plus_399k':
      return AiseeRevenueCatProduct.plus399k;
    case 'basic_149k':
      return AiseeRevenueCatProduct.basic149k;
    default:
      return AiseeRevenueCatProduct.basic149k;
  }
}

class _UpgradeHintCard extends StatelessWidget {
  const _UpgradeHintCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.subscriptionSuggestUpgrade,
      child: Material(
        color: StyleTokens.buttonPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const Icon(Icons.trending_up, color: StyleTokens.buttonPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.subscriptionQuotaLowWarning,
                    style: StyleTokens.bodySmall().copyWith(
                      color: StyleTokens.textPrimary,
                    ),
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

class _RevenueCatDisabledCard extends StatelessWidget {
  const _RevenueCatDisabledCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              color: StyleTokens.buttonPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.subscriptionTemporaryUnavailable,
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPickerSheet extends StatefulWidget {
  const _PlanPickerSheet({
    required this.overview,
    required this.optionsFuture,
    required this.onPurchased,
  });

  final AiseeBillingOverview overview;
  final Future<List<AiseeRevenueCatPackageOption>> optionsFuture;
  final Future<void> Function(AiseeRevenueCatPackageOption option) onPurchased;

  @override
  State<_PlanPickerSheet> createState() => _PlanPickerSheetState();
}

class _PlanPickerSheetState extends State<_PlanPickerSheet> {
  List<AiseeRevenueCatPackageOption>? _options;
  AiseeRevenueCatPackageOption? _selected;
  String? _error;
  bool _buying = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    widget.optionsFuture
        .then((List<AiseeRevenueCatPackageOption> options) {
          if (!mounted) return;
          setState(() {
            _options = options;
            _selected =
                _recommendedOption(widget.overview, options) ??
                (options.isNotEmpty ? options.first : null);
          });
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() => _error = error.toString());
        });
  }

  Future<void> _buySelected() async {
    final AiseeRevenueCatPackageOption? selected = _selected;
    if (_buying || selected == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _buying = true);
    try {
      final customerInfo = await AiseeRevenueCatService.instance.purchaseOption(
        selected,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (AiseeRevenueCatService.hasAiSeePro(customerInfo)) {
        await widget.onPurchased(selected);
      } else {
        AppToast.show(l10n.subscriptionTransactionRecorded);
      }
    } on AiseeRevenueCatException catch (e) {
      if (!mounted || e.cancelled) return;
      AppToast.show(e.message, isError: true);
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final List<AiseeRevenueCatPackageOption>? options = _options;
    final AiseeRevenueCatPackageOption? selected = _selected;
    final bool canSubmit = _canSubmitSelectedPlan(
      widget.overview,
      selected,
      buying: _buying,
    );
    final AppLocalizations l10n = this.l10n;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Container(
        decoration: const BoxDecoration(
          color: StyleTokens.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
          child: Column(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.subscriptionChooseCarePlan,
                          style: aiseeTextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: StyleTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.subscriptionStorePaymentInfo(
                            widget.overview.careGroup.name,
                          ),
                          style: StyleTokens.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.subscriptionClose,
                    onPressed: _buying
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                _PlanPickerError(message: _error!)
              else if (options == null)
                const _PlanPickerLoading()
              else
                Column(
                  children: <Widget>[
                    for (int index = 0; index < options.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: index == options.length - 1 ? 0 : 8,
                        ),
                        child: _PlanOptionCard(
                          option: options[index],
                          selected: options[index] == selected,
                          enabled: canUpgradeToSubscriptionProduct(
                            widget.overview,
                            options[index].product,
                          ),
                          hint: _planOptionHintLocalized(
                            widget.overview,
                            options[index].product,
                            l10n,
                          ),
                          onTap:
                              _buying ||
                                  !canUpgradeToSubscriptionProduct(
                                    widget.overview,
                                    options[index].product,
                                  )
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selected = options[index]);
                                },
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Expanded(
                child: selected == null
                    ? const SizedBox.shrink()
                    : _ExpandedPlanDetails(
                        product: selected.product,
                        current: _isCurrentPlan(
                          widget.overview,
                          selected.product,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              _PrimaryButton(
                label: _planPickerActionLabel(
                  widget.overview,
                  selected,
                  buying: _buying,
                  processingLabel: l10n.subscriptionProcessing,
                  chooseToContinueLabel: l10n.subscriptionChooseToContinue,
                  alreadyHighestLabel: l10n.subscriptionAlreadyHighest,
                  alreadyUsingLabel: l10n.subscriptionAlreadyUsing,
                  upgradeOnlyLabel: l10n.subscriptionUpgradeOnly,
                  continueWithTemplate: l10n.subscriptionContinueWith('{plan}'),
                ),
                onTap: canSubmit ? _buySelected : () {},
                enabled: canSubmit,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.subscriptionPriceNoteVND,
                textAlign: TextAlign.center,
                style: StyleTokens.bodySmall().copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedPlanDetails extends StatelessWidget {
  const _ExpandedPlanDetails({required this.product, required this.current});

  final AiseeRevenueCatProduct product;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.checklist,
            title: l10n.subscriptionFeaturesInPlan,
            trailing: _PlanDetailBadges(
              current: current,
              popular: _isPopular(product),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (final _PlanFeatureLine feature in _planExpandedFeatures(
                    product,
                    l10n,
                  ))
                    _PlanFeatureToggle(feature: feature),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFeatureLine {
  const _PlanFeatureLine({required this.title, required this.detail});

  final String title;
  final String detail;
}

class _PlanDetailBadges extends StatelessWidget {
  const _PlanDetailBadges({required this.current, required this.popular});

  final bool current;
  final bool popular;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!current && !popular) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (current) _SmallPill(label: l10n.subscriptionUsing),
        if (current && popular) const SizedBox(width: 6),
        if (popular) _SmallPill(label: l10n.subscriptionSuitable),
      ],
    );
  }
}

class _PlanFeatureToggle extends StatefulWidget {
  const _PlanFeatureToggle({required this.feature});

  final _PlanFeatureLine feature;

  @override
  State<_PlanFeatureToggle> createState() => _PlanFeatureToggleState();
}

class _PlanFeatureToggleState extends State<_PlanFeatureToggle> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.check_circle,
                    size: 17,
                    color: StyleTokens.buttonPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.feature.title,
                      style: aiseeTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: StyleTokens.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: StyleTokens.textMuted,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(left: 25, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.feature.detail,
                      style: StyleTokens.bodySmall().copyWith(fontSize: 12),
                    ),
                  ),
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 160),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.hint,
  });

  final AiseeRevenueCatPackageOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color border = selected
        ? StyleTokens.buttonPrimary
        : StyleTokens.cardBorder;
    final Color surface = selected
        ? StyleTokens.buttonPrimary.withValues(alpha: 0.06)
        : StyleTokens.surfaceCard;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label:
          '${planNameForProduct(option.product)} ${_fallbackVndPrice(option.product)}',
      child: Material(
        color: enabled ? surface : surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: selected ? 1.6 : 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: !enabled
                      ? StyleTokens.textMuted.withValues(alpha: 0.7)
                      : selected
                      ? StyleTokens.buttonPrimary
                      : StyleTokens.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        planNameForProduct(option.product),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aiseeTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: enabled
                              ? StyleTokens.textPrimary
                              : StyleTokens.textSecondary,
                        ),
                      ),
                      if (hint != null) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          hint!,
                          style: StyleTokens.bodySmall().copyWith(
                            fontSize: 11,
                            color: StyleTokens.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _fallbackVndPrice(option.product),
                      textAlign: TextAlign.right,
                      style: aiseeTextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: enabled
                            ? StyleTokens.buttonPrimary
                            : StyleTokens.textMuted,
                      ),
                    ),
                    Text(
                      l10n.subscriptionPriceMonthSuffix,
                      style: StyleTokens.bodySmall().copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanPickerLoading extends StatelessWidget {
  const _PlanPickerLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const <Widget>[
        _LoadingPlanCard(widthFactor: 0.70),
        SizedBox(height: 10),
        _LoadingPlanCard(widthFactor: 0.86),
        SizedBox(height: 10),
        _LoadingPlanCard(widthFactor: 0.78),
      ],
    );
  }
}

class _LoadingPlanCard extends StatelessWidget {
  const _LoadingPlanCard({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          const _SkeletonBar(width: 22, height: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: const _SkeletonBar(height: 14),
                ),
                const SizedBox(height: 8),
                const FractionallySizedBox(
                  widthFactor: 0.82,
                  child: _SkeletonBar(height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 82, child: _SkeletonBar(height: 16)),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StyleTokens.cardBorder.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _PlanPickerError extends StatelessWidget {
  const _PlanPickerError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.error_outline, color: StyleTokens.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StyleTokens.buttonPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: aiseeTextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: StyleTokens.buttonPrimary,
        ),
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quotas});

  final List<AiseeUsageQuota> quotas;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<AiseeUsageQuota> sorted = <AiseeUsageQuota>[...quotas]
      ..sort((a, b) => a.usageType.compareTo(b.usageType));
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.speed,
            title: l10n.subscriptionQuotaRemaining,
          ),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            Text(l10n.subscriptionNoQuota, style: StyleTokens.bodySmall())
          else
            for (final AiseeUsageQuota quota in sorted)
              _InfoRow(
                title: _quotaLabel(quota.usageType, l10n),
                value: quota.unlimited
                    ? l10n.subscriptionUnlimitedReasonable
                    : '${_trimNumber(quota.remaining)} / '
                          '${_trimNumber(quota.limit + quota.granted)} '
                          '${quota.unit ?? ''}',
                warning: quota.upgradeSuggested,
              ),
        ],
      ),
    );
  }
}

class _EntitlementsCard extends StatelessWidget {
  const _EntitlementsCard({required this.overview, required this.showEnabled});

  final AiseeBillingOverview overview;
  final bool showEnabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<_FeatureLine> features = _getKnownFeatures(l10n)
        .where(
          (feature) => overview.entitlementEnabled(feature.key) == showEnabled,
        )
        .toList();
    return _CollapsibleSectionCard(
      icon: showEnabled ? Icons.verified : Icons.lock,
      title: showEnabled
          ? l10n.subscriptionActiveEntitlements
          : l10n.subscriptionLockedFeatures,
      trailing: _SmallPill(label: features.length.toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (features.isEmpty)
            Text(
              showEnabled
                  ? l10n.subscriptionNoEntitlements
                  : l10n.subscriptionNoLockedFeatures,
              style: StyleTokens.bodySmall(),
            )
          else
            for (final _FeatureLine feature in features)
              _InfoRow(title: feature.label, value: feature.description),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.events});

  final List<AiseeSubscriptionEvent> events;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _CollapsibleSectionCard(
      icon: Icons.receipt_long,
      title: l10n.subscriptionPlanHistory,
      trailing: _SmallPill(label: events.length.toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (events.isEmpty)
            Text(l10n.subscriptionNoHistory, style: StyleTokens.bodySmall())
          else
            for (final AiseeSubscriptionEvent event in events.take(5))
              _InfoRow(
                title: _eventLabelLocalized(event.eventType, l10n),
                value: _eventDetail(event),
              ),
        ],
      ),
    );
  }
}

class _InvoicePlaceholderCard extends StatelessWidget {
  const _InvoicePlaceholderCard({
    required this.overview,
    required this.revenueCatEnabled,
  });

  final AiseeBillingOverview overview;
  final bool revenueCatEnabled;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.subscriptionInvoiceDetail,
            style: aiseeTextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            revenueCatEnabled
                ? l10n.subscriptionInvoicePlaceholder
                : l10n.subscriptionBillingHistoryPlaceholder,
            style: StyleTokens.bodySmall(),
          ),
          const SizedBox(height: 12),
          if (revenueCatEnabled &&
              overview.storeManagement.manageUrl != null &&
              overview.storeManagement.manageUrl!.isNotEmpty)
            _SecondaryButton(
              label: l10n.subscriptionOpenStoreManagement,
              onTap: () async {
                final Uri u = Uri.parse(overview.storeManagement.manageUrl!);
                if (await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.overview,
    required this.revenueCatEnabled,
    required this.canManageStore,
    required this.onManage,
    required this.onCustomerCenter,
    required this.onRestore,
  });

  final AiseeBillingOverview overview;
  final bool revenueCatEnabled;
  final bool canManageStore;
  final VoidCallback onManage;
  final VoidCallback onCustomerCenter;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.storefront,
            title: l10n.subscriptionManageSubscription,
          ),
          const SizedBox(height: 8),
          Text(
            revenueCatEnabled
                ? overview.storeManagement.instructions
                : l10n.subscriptionTemporaryUnavailable,
            style: StyleTokens.bodySmall(),
          ),
          if (canManageStore && overview.subscription != null) ...<Widget>[
            const SizedBox(height: 14),
            _SecondaryButton(
              label: l10n.subscriptionOpenCustomerCenter,
              onTap: onCustomerCenter,
            ),
            const SizedBox(height: 10),
            _SecondaryButton(
              label: l10n.subscriptionOpenStorePage,
              onTap: onManage,
            ),
          ],
          if (canManageStore) ...<Widget>[
            const SizedBox(height: 10),
            _SecondaryButton(
              label: l10n.subscriptionSyncTransactions,
              onTap: onRestore,
            ),
          ],
        ],
      ),
    );
  }
}

class _BillingScreenContext {
  const _BillingScreenContext({this.careGroupId, this.caredUserId});

  final String? careGroupId;
  final String? caredUserId;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _CollapsibleSectionCard extends StatefulWidget {
  const _CollapsibleSectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  State<_CollapsibleSectionCard> createState() =>
      _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<_CollapsibleSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Icon(
                      widget.icon,
                      size: 18,
                      color: StyleTokens.buttonPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: aiseeTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                    ),
                    ?widget.trailing,
                    if (widget.trailing != null) const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22,
                      color: StyleTokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: widget.child,
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 160),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: StyleTokens.buttonPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: aiseeTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
    this.warning = false,
  });

  final String title;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            warning ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: warning ? Colors.orange.shade700 : StyleTokens.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: StyleTokens.bodySmall().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: positive
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: aiseeTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: positive ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? StyleTokens.buttonPrimary
          : StyleTokens.cardBorder.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(31),
      child: InkWell(
        borderRadius: BorderRadius.circular(31),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: StyleTokens.socialLabel().copyWith(
                fontSize: 13,
                color: enabled ? StyleTokens.background : StyleTokens.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.background,
      borderRadius: BorderRadius.circular(31),
      child: InkWell(
        borderRadius: BorderRadius.circular(31),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: aiseeTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: StyleTokens.buttonPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureLine {
  const _FeatureLine(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;
}

List<_FeatureLine> _getKnownFeatures(AppLocalizations l) {
  return <_FeatureLine>[
    _FeatureLine(
      'sos_enabled',
      l.subscriptionDavoFeaturesSos,
      l.subscriptionDavoFeaturesSosDesc,
    ),
    _FeatureLine(
      'medication_reminders_enabled',
      l.subscriptionDavoFeaturesMeds,
      l.subscriptionDavoFeaturesMedsDesc,
    ),
    _FeatureLine(
      'daily_brief_enabled',
      l.subscriptionDavoFeaturesDailyBrief,
      l.subscriptionDavoFeaturesDailyBriefDesc,
    ),
    _FeatureLine(
      'weekly_report_enabled',
      l.subscriptionDavoFeaturesWeeklyReport,
      l.subscriptionDavoFeaturesWeeklyReportDesc,
    ),
    _FeatureLine(
      'weekly_report_pdf_enabled',
      l.subscriptionDavoFeaturesPdfExport,
      l.subscriptionDavoFeaturesPdfExportDesc,
    ),
    _FeatureLine(
      'smart_alert_enabled',
      l.subscriptionDavoFeaturesSmartAlert,
      l.subscriptionDavoFeaturesSmartAlertDesc,
    ),
    _FeatureLine(
      'incident_report_enabled',
      l.subscriptionDavoFeaturesIncidentReport,
      l.subscriptionDavoFeaturesIncidentReportDesc,
    ),
    _FeatureLine(
      'priority_support_enabled',
      l.subscriptionDavoFeaturesPrioritySupport,
      l.subscriptionDavoFeaturesPrioritySupportDesc,
    ),
  ];
}

String _formatPrice(AiseeBillingPlan plan, AppLocalizations l) {
  if (plan.priceVnd == 0) {
    return l.subscriptionFree;
  }
  final String raw = plan.priceVnd.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return l.subscriptionVndPricePerMonth(buffer.toString());
}

String _quotaLabel(String usageType, AppLocalizations l) {
  switch (usageType) {
    case 'ai_minutes':
    case 'ai_minutes_per_month':
      return l.localeName.startsWith('vi') ? 'Phút AI' : 'AI minutes';
    case 'camera_activations':
    case 'camera_activations_per_day':
      return l.localeName.startsWith('vi')
          ? 'Lượt camera'
          : 'Camera activations';
    case 'voice_call_minutes':
    case 'voice_calls':
    case 'voice_calls_enabled':
      return l.localeName.startsWith('vi')
          ? 'Phút gọi thoại'
          : 'Voice call minutes';
    case 'video_call_minutes':
    case 'video_calls':
    case 'video_calls_enabled':
    case 'video_calls_per_day':
      return l.localeName.startsWith('vi')
          ? 'Phút gọi video'
          : 'Video call minutes';
    case 'pdf_exports':
    case 'care_pdf_exports':
    case 'csv_exports_per_month':
      return l.localeName.startsWith('vi') ? 'Xuất PDF' : 'PDF export';
    case 'care_coach_questions':
      return l.localeName.startsWith('vi')
          ? 'Câu hỏi chăm sóc'
          : 'Care questions';
    case 'pattern_detection_runs':
      return l.localeName.startsWith('vi')
          ? 'Phân tích xu hướng'
          : 'Trend analysis';
    default:
      return usageType;
  }
}

String _eventLabelLocalized(String eventType, AppLocalizations l10n) {
  final String normalized = _normalizedEventType(eventType);
  switch (normalized) {
    case 'initial_purchase':
    case 'started':
    case 'start':
    case 'subscription_started':
      return l10n.subscriptionPlanStarted;
    case 'renewal':
    case 'renewed':
    case 'subscription_renewed':
      return l10n.subscriptionPlanRenewed;
    case 'cancellation':
    case 'canceled':
    case 'cancelled':
      return l10n.subscriptionPlanRenewalOff;
    case 'expiration':
    case 'expired':
      return l10n.subscriptionPlanExpired;
    case 'product_change':
    case 'changed':
    case 'subscription_changed':
      return l10n.subscriptionPlanChanged;
    case 'uncancellation':
      return l10n.subscriptionPlanRenewalOn;
    case 'billing_issue':
      return l10n.subscriptionPlanBillingError;
    case 'subscription_paused':
    case 'paused':
      return l10n.subscriptionPlanPaused;
    case 'non_renewing_purchase':
      return l10n.subscriptionPlanPurchasedNonRenewing;
    case 'transfer':
      return l10n.subscriptionPlanOwnershipTransferred;
    case 'subscriber_alias':
      return l10n.subscriptionPlanAccountLinked;
    case 'subscription_canceled':
      return l10n.subscriptionPlanCancelled;
    default:
      return _humanizeEventType(normalized);
  }
}

String _eventDetail(AiseeSubscriptionEvent event) {
  final String date = _formatDate(event.createdAt);
  final String provider = _providerLabel(event.provider);
  if (date.isEmpty) return provider;
  return '$date · $provider';
}

String _normalizedEventType(String eventType) {
  String normalized = eventType.trim().toLowerCase().replaceAll('-', '_');
  for (final String prefix in <String>['revenuecat_', 'subscription_']) {
    if (normalized.startsWith(prefix)) {
      normalized = normalized.substring(prefix.length);
      break;
    }
  }
  return normalized;
}

String _humanizeEventType(String eventType) {
  if (eventType.isEmpty) return 'plan_updated'; // resolved by caller
  final String spaced = eventType.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String _providerLabel(String? provider) {
  switch ((provider ?? '').trim().toLowerCase()) {
    case 'revenuecat_app_store':
      return 'App Store';
    case 'revenuecat_play_store':
      return 'Google Play';
    case 'revenuecat':
      return 'RevenueCat';
    case 'manual':
      return 'granted_manually'; // key
    case '':
      return 'AiSee';
    default:
      return provider!;
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _trimNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String planNameForProduct(AiseeRevenueCatProduct product) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return 'Care Basic';
    case AiseeRevenueCatProduct.plus399k:
      return 'Care Plus';
    case AiseeRevenueCatProduct.premium599k:
      return 'Care Premium';
  }
}

List<_PlanFeatureLine> _planExpandedFeatures(
  AiseeRevenueCatProduct product,
  AppLocalizations l,
) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: l.subscriptionPlanFeatureBasic1,
          detail: l.subscriptionPlanFeatureBasic1Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeatureBasic2,
          detail: l.subscriptionPlanFeatureBasic2Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeatureBasic3,
          detail: l.subscriptionPlanFeatureBasic3Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeatureBasic4,
          detail: l.subscriptionPlanFeatureBasic4Desc,
        ),
      ];
    case AiseeRevenueCatProduct.plus399k:
      return <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePlus1,
          detail: l.subscriptionPlanFeaturePlus1Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePlus2,
          detail: l.subscriptionPlanFeaturePlus2Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePlus3,
          detail: l.subscriptionPlanFeaturePlus3Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePlus4,
          detail: l.subscriptionPlanFeaturePlus4Desc,
        ),
      ];
    case AiseeRevenueCatProduct.premium599k:
      return <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePremium1,
          detail: l.subscriptionPlanFeaturePremium1Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePremium2,
          detail: l.subscriptionPlanFeaturePremium2Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePremium3,
          detail: l.subscriptionPlanFeaturePremium3Desc,
        ),
        _PlanFeatureLine(
          title: l.subscriptionPlanFeaturePremium4,
          detail: l.subscriptionPlanFeaturePremium4Desc,
        ),
      ];
  }
}

String _fallbackVndPrice(AiseeRevenueCatProduct product) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return '149.000 VND';
    case AiseeRevenueCatProduct.plus399k:
      return '399.000 VND';
    case AiseeRevenueCatProduct.premium599k:
      return '599.000 VND';
  }
}

String _planCodeForProduct(AiseeRevenueCatProduct product) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return 'basic_149k';
    case AiseeRevenueCatProduct.plus399k:
      return 'plus_399k';
    case AiseeRevenueCatProduct.premium599k:
      return 'premium_599k';
  }
}

bool _isPopular(AiseeRevenueCatProduct product) {
  return product == AiseeRevenueCatProduct.plus399k;
}

bool _isCurrentPlan(
  AiseeBillingOverview overview,
  AiseeRevenueCatProduct product,
) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return _currentPlanCode(overview) == 'basic_149k';
    case AiseeRevenueCatProduct.plus399k:
      return _currentPlanCode(overview) == 'plus_399k';
    case AiseeRevenueCatProduct.premium599k:
      return _currentPlanCode(overview) == 'premium_599k';
  }
}
