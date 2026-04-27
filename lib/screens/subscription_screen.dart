import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_billing_service.dart';
import '../services/aisee_profile_cache.dart';
import '../services/aisee_revenuecat_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../widgets/app_wordmark.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, this.familyFirst = false});

  final bool familyFirst;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final AiseeBillingService _billingService = AiseeBillingService();
  AiseeBillingOverview? _overview;
  bool _loading = true;
  bool _revenueCatBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(AiseeAnalyticsService.instance.trackScreen('subscription'));
    unawaited(
      AiseeAnalyticsService.instance.track(AiseeAnalyticsEvent.pricingViewed),
    );
    _load();
  }

  @override
  void dispose() {
    _billingService.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
      if (tokens == null) {
        throw AiseeApiException('Phiên đăng nhập hết hạn');
      }
      final AiseeBillingOverview overview = await _billingService
          .fetchBillingOverview(tokens.accessToken);
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

  Future<void> _openStoreManagement(AiseeBillingOverview overview) async {
    HapticFeedback.lightImpact();
    final String? url = overview.storeManagement.manageUrl;
    if (url == null || url.isEmpty) {
      AppToast.show(overview.storeManagement.instructions);
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppToast.show('Không mở được trang quản lý gói', isError: true);
    }
  }

  Future<void> _startUpgrade(AiseeBillingOverview overview) async {
    HapticFeedback.mediumImpact();
    await AiseeAnalyticsService.instance.track(
      AiseeAnalyticsEvent.upgradeClicked,
      parameters: <String, Object?>{
        'plan_code': overview.effectivePlan.code,
        'care_group_id': overview.careGroup.id,
      },
    );
    if (!overview.careGroup.canManageBilling) {
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
      AppToast.show('Chỉ chủ nhóm hoặc quản trị thanh toán mới nâng gói.');
      return;
    }
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show('Phiên đăng nhập hết hạn', isError: true);
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
    AppToast.show('Thanh toán thành công. AiSee đang đồng bộ gói.');
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
      AppToast.show('Gói ${_planName(option.product)} đã được cập nhật.');
    } else {
      AppToast.show(
        'Giao dịch đã thành công nhưng backend chưa nhận webhook RevenueCat.',
        isError: true,
      );
    }
  }

  Future<bool> _waitForBillingSync(AiseeRevenueCatProduct product) async {
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) return false;
    final String expectedPlanCode = _planCodeForProduct(product);
    for (int attempt = 0; attempt < 8; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      try {
        final AiseeBillingOverview next = await _billingService
            .fetchBillingOverview(tokens.accessToken);
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
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show('Phiên đăng nhập hết hạn', isError: true);
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
        AppToast.show('Đã đồng bộ AiSee Pro. AiSee đang cập nhật gói.');
        await _load();
      } else {
        AppToast.show('Chưa tìm thấy gói AiSee Pro trên tài khoản này.');
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
    if (_revenueCatBusy) return;
    final AiseeUserProfile? profile = await AiseeProfileCache.instance.read();
    if (profile == null) {
      AppToast.show('Phiên đăng nhập hết hạn', isError: true);
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
                'Gói AiSee',
                style: GoogleFonts.plusJakartaSans(
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
              _PrimaryButton(label: 'Thử lại', onTap: _load),
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
            onUpgrade: () => _startUpgrade(overview),
          ),
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
          _StoreCard(
            overview: overview,
            onManage: () => _openStoreManagement(overview),
            onCustomerCenter: () => _openCustomerCenter(overview),
            onRestore: () => _restorePurchases(overview),
          ),
        ],
      ),
    );
  }

  bool _shouldSuggestUpgrade(AiseeBillingOverview overview) {
    if (!widget.familyFirst || !overview.careGroup.canManageBilling) {
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
  AiseeRevenueCatProduct target = AiseeRevenueCatProduct.basic149k;
  switch (overview.effectivePlan.code) {
    case 'basic_149k':
      target = AiseeRevenueCatProduct.basic149k;
    case 'plus_399k':
      target = AiseeRevenueCatProduct.plus399k;
    case 'premium_599k':
      target = AiseeRevenueCatProduct.premium599k;
  }
  for (final AiseeRevenueCatPackageOption option in options) {
    if (option.product == target) return option;
  }
  return null;
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.overview, required this.onUpgrade});

  final AiseeBillingOverview overview;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final AiseeSubscription? subscription = overview.subscription;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.workspace_premium,
            title: 'Gói hiện tại',
            trailing: _StatusPill(
              label: subscription?.status ?? 'free',
              positive:
                  subscription?.status == 'active' ||
                  overview.effectivePlan.isFree,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            overview.effectivePlan.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrice(overview.effectivePlan),
            style: StyleTokens.bodySmall().copyWith(
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${overview.careGroup.name} · '
            '${overview.careGroup.caredUserCount} người được chăm sóc · '
            '${overview.careGroup.memberCount} người thân',
            style: StyleTokens.bodySmall().copyWith(fontSize: 12),
          ),
          if (subscription?.cancelAtPeriodEnd ?? false) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Gói sẽ dừng gia hạn ở cuối chu kỳ hiện tại.',
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textSecondary,
              ),
            ),
          ],
          if (overview.careGroup.canManageBilling ||
              overview.effectivePlan.isFree) ...<Widget>[
            const SizedBox(height: 16),
            _PrimaryButton(
              label: overview.effectivePlan.isFree
                  ? 'Xem gói để mua'
                  : 'Xem gói phù hợp',
              onTap: onUpgrade,
            ),
          ],
        ],
      ),
    );
  }
}

class _UpgradeHintCard extends StatelessWidget {
  const _UpgradeHintCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Gợi ý nâng gói. Chạm để xem gói phù hợp.',
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
                    'Nhóm đang dùng gần hết quota. Nâng gói giúp gia đình theo dõi ổn định hơn.',
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
        AppToast.show('Giao dịch đã ghi nhận. AiSee đang đồng bộ.');
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
                          'Chọn gói chăm sóc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: StyleTokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.overview.careGroup.name} · thanh toán qua cửa hàng ứng dụng',
                          style: StyleTokens.bodySmall(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
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
                          onTap: _buying
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
                label: _buying
                    ? 'Đang xử lý...'
                    : selected == null
                    ? 'Đang tải gói...'
                    : 'Tiếp tục với ${_planName(selected.product)}',
                onTap: _buying || selected == null ? () {} : _buySelected,
              ),
              const SizedBox(height: 8),
              Text(
                'Giá VND theo bảng gói AiSee. Thanh toán, gia hạn và hủy gói vẫn được xử lý qua cửa hàng ứng dụng.',
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
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(
            icon: Icons.checklist,
            title: 'Tính năng trong gói',
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
    if (!current && !popular) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (current) const _SmallPill(label: 'Đang dùng'),
        if (current && popular) const SizedBox(width: 6),
        if (popular) const _SmallPill(label: 'Phù hợp'),
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
                      style: GoogleFonts.plusJakartaSans(
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
    required this.onTap,
  });

  final AiseeRevenueCatPackageOption option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = selected
        ? StyleTokens.buttonPrimary
        : StyleTokens.cardBorder;
    final Color surface = selected
        ? StyleTokens.buttonPrimary.withValues(alpha: 0.06)
        : StyleTokens.surfaceCard;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${_planName(option.product)} ${_fallbackVndPrice(option.product)}',
      child: Material(
        color: surface,
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
                  color: selected
                      ? StyleTokens.buttonPrimary
                      : StyleTokens.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _planName(option.product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: StyleTokens.textPrimary,
                    ),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: StyleTokens.buttonPrimary,
                      ),
                    ),
                    Text(
                      '/ tháng',
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
        style: GoogleFonts.plusJakartaSans(
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
    final List<AiseeUsageQuota> sorted = <AiseeUsageQuota>[...quotas]
      ..sort((a, b) => a.usageType.compareTo(b.usageType));
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(icon: Icons.speed, title: 'Quota còn lại'),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            Text('Chưa có quota sử dụng.', style: StyleTokens.bodySmall())
          else
            for (final AiseeUsageQuota quota in sorted)
              _InfoRow(
                title: _quotaLabel(quota.usageType),
                value: quota.unlimited
                    ? 'Không giới hạn hợp lý'
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
    final List<_FeatureLine> features = _knownFeatures
        .where(
          (feature) => overview.entitlementEnabled(feature.key) == showEnabled,
        )
        .toList();
    return _CollapsibleSectionCard(
      icon: showEnabled ? Icons.verified : Icons.lock,
      title: showEnabled ? 'Quyền đang có' : 'Tính năng bị khóa',
      trailing: _SmallPill(label: features.length.toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (features.isEmpty)
            Text(
              showEnabled
                  ? 'Chưa có quyền nào được bật.'
                  : 'Không có tính năng khóa trong gói này.',
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
    return _CollapsibleSectionCard(
      icon: Icons.receipt_long,
      title: 'Lịch sử gói',
      trailing: _SmallPill(label: events.length.toString()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (events.isEmpty)
            Text(
              'Chưa có lịch sử hóa đơn hoặc thay đổi gói.',
              style: StyleTokens.bodySmall(),
            )
          else
            for (final AiseeSubscriptionEvent event in events.take(5))
              _InfoRow(
                title: _eventLabel(event.eventType),
                value: _eventDetail(event),
              ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.overview,
    required this.onManage,
    required this.onCustomerCenter,
    required this.onRestore,
  });

  final AiseeBillingOverview overview;
  final VoidCallback onManage;
  final VoidCallback onCustomerCenter;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(
            icon: Icons.storefront,
            title: 'Quản lý subscription',
          ),
          const SizedBox(height: 8),
          Text(
            overview.storeManagement.instructions,
            style: StyleTokens.bodySmall(),
          ),
          if (overview.subscription != null) ...<Widget>[
            const SizedBox(height: 14),
            _SecondaryButton(
              label: 'Mở trung tâm khách hàng',
              onTap: onCustomerCenter,
            ),
            const SizedBox(height: 10),
            _SecondaryButton(label: 'Mở trang quản lý store', onTap: onManage),
          ],
          const SizedBox(height: 10),
          _SecondaryButton(label: 'Đồng bộ giao dịch', onTap: onRestore),
        ],
      ),
    );
  }
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
                        style: GoogleFonts.plusJakartaSans(
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
            style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: positive ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.buttonPrimary,
      borderRadius: BorderRadius.circular(31),
      child: InkWell(
        borderRadius: BorderRadius.circular(31),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          child: Center(
            child: Text(
              label,
              style: StyleTokens.socialLabel().copyWith(fontSize: 13),
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
              style: GoogleFonts.plusJakartaSans(
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

const List<_FeatureLine> _knownFeatures = <_FeatureLine>[
  _FeatureLine('sos_enabled', 'SOS khẩn cấp', 'Gửi cảnh báo tới người thân.'),
  _FeatureLine(
    'medication_reminders_enabled',
    'Nhắc thuốc',
    'Theo dõi lịch uống thuốc và lịch khám.',
  ),
  _FeatureLine(
    'daily_brief_enabled',
    'Tóm tắt hằng ngày',
    'Gia đình nhận tóm tắt chăm sóc trong ngày.',
  ),
  _FeatureLine(
    'weekly_report_enabled',
    'Báo cáo tuần',
    'Tổng hợp xu hướng sức khỏe và hoạt động.',
  ),
  _FeatureLine(
    'weekly_report_pdf_enabled',
    'Xuất báo cáo PDF',
    'Tải báo cáo chăm sóc để lưu hoặc gửi bác sĩ.',
  ),
  _FeatureLine(
    'smart_alert_enabled',
    'Cảnh báo thông minh',
    'Nhận tín hiệu bất thường chủ động hơn.',
  ),
  _FeatureLine(
    'incident_report_enabled',
    'Báo cáo sự cố',
    'Lưu lại các sự kiện cần gia đình theo dõi.',
  ),
  _FeatureLine(
    'priority_support_enabled',
    'Hỗ trợ ưu tiên',
    'Ưu tiên xử lý khi cần hỗ trợ.',
  ),
];

String _formatPrice(AiseeBillingPlan plan) {
  if (plan.priceVnd == 0) return 'Miễn phí';
  final String raw = plan.priceVnd.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int remaining = raw.length - i;
    buffer.write(raw[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }
  return '${buffer.toString()}đ / tháng';
}

String _quotaLabel(String usageType) {
  switch (usageType) {
    case 'ai_minutes':
      return 'Phút AI';
    case 'camera_activations':
      return 'Lượt camera';
    case 'voice_call_minutes':
      return 'Phút gọi thoại';
    case 'video_call_minutes':
      return 'Phút gọi video';
    case 'pdf_exports':
      return 'Xuất PDF';
    case 'care_coach_questions':
      return 'Câu hỏi chăm sóc';
    case 'pattern_detection_runs':
      return 'Phân tích xu hướng';
    default:
      return usageType;
  }
}

String _eventLabel(String eventType) {
  final String normalized = _normalizedEventType(eventType);
  switch (normalized) {
    case 'initial_purchase':
    case 'started':
    case 'start':
      return 'Bắt đầu gói';
    case 'renewal':
    case 'renewed':
      return 'Gia hạn gói';
    case 'cancellation':
    case 'canceled':
    case 'cancelled':
      return 'Hủy gia hạn';
    case 'expiration':
    case 'expired':
      return 'Gói hết hạn';
    case 'product_change':
    case 'changed':
      return 'Đổi gói';
    case 'uncancellation':
      return 'Bật lại gia hạn';
    case 'billing_issue':
      return 'Lỗi thanh toán';
    case 'subscription_paused':
    case 'paused':
      return 'Tạm dừng gói';
    case 'non_renewing_purchase':
      return 'Mua gói không gia hạn';
    case 'transfer':
      return 'Chuyển quyền mua';
    case 'subscriber_alias':
      return 'Liên kết tài khoản mua';
    case 'subscription_renewed':
      return 'Gia hạn gói';
    case 'subscription_started':
      return 'Bắt đầu gói';
    case 'subscription_canceled':
      return 'Hủy gói';
    case 'subscription_changed':
      return 'Đổi gói';
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
  if (eventType.isEmpty) return 'Cập nhật gói';
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
      return 'Cấp thủ công';
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

String _planName(AiseeRevenueCatProduct product) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return 'AiSee Basic';
    case AiseeRevenueCatProduct.plus399k:
      return 'AiSee Plus';
    case AiseeRevenueCatProduct.premium599k:
      return 'AiSee Premium';
  }
}

List<_PlanFeatureLine> _planExpandedFeatures(AiseeRevenueCatProduct product) {
  switch (product) {
    case AiseeRevenueCatProduct.basic149k:
      return const <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: '150 phút AI mỗi tháng',
          detail:
              'Phù hợp cho một người dùng chính với nhu cầu theo dõi cơ bản.',
        ),
        _PlanFeatureLine(
          title: '3 lần bật camera mỗi ngày',
          detail: 'Kiểm tra nhanh tình huống khi người dùng cần hỗ trợ.',
        ),
        _PlanFeatureLine(
          title: 'Timeline chăm sóc 7 ngày',
          detail: 'Xem lại hoạt động gần đây của gia đình trong tuần.',
        ),
        _PlanFeatureLine(
          title: '2 thành viên gia đình',
          detail:
              'Cho phép thêm người thân cùng theo dõi một người được chăm sóc.',
        ),
      ];
    case AiseeRevenueCatProduct.plus399k:
      return const <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: '600 phút AI mỗi tháng',
          detail: 'Dư dùng hơn cho gia đình cần trợ lý hoạt động thường xuyên.',
        ),
        _PlanFeatureLine(
          title: '20 lần bật camera mỗi ngày',
          detail:
              'Theo dõi linh hoạt hơn khi có nhiều tình huống cần kiểm tra.',
        ),
        _PlanFeatureLine(
          title: 'Daily brief và weekly report',
          detail: 'Tóm tắt chăm sóc định kỳ để gia đình nắm tình hình nhanh.',
        ),
        _PlanFeatureLine(
          title: '5 thành viên, 3 người được chăm sóc',
          detail: 'Phù hợp cho gia đình có nhiều người cùng quản lý.',
        ),
      ];
    case AiseeRevenueCatProduct.premium599k:
      return const <_PlanFeatureLine>[
        _PlanFeatureLine(
          title: 'AI và camera fair use',
          detail:
              'Ưu tiên trải nghiệm gần như không giới hạn theo chính sách hợp lý.',
        ),
        _PlanFeatureLine(
          title: 'Báo cáo nâng cao PDF/CSV',
          detail: 'Xuất báo cáo chăm sóc để lưu trữ hoặc chia sẻ khi cần.',
        ),
        _PlanFeatureLine(
          title: '10 thành viên, 4 người được chăm sóc',
          detail: 'Dành cho nhóm gia đình lớn hoặc chăm sóc nhiều người.',
        ),
        _PlanFeatureLine(
          title: 'Hỗ trợ ưu tiên và incident report',
          detail: 'Tăng mức hỗ trợ vận hành khi có tình huống quan trọng.',
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
      return overview.effectivePlan.code == 'basic_149k';
    case AiseeRevenueCatProduct.plus399k:
      return overview.effectivePlan.code == 'plus_399k';
    case AiseeRevenueCatProduct.premium599k:
      return overview.effectivePlan.code == 'premium_599k';
  }
}
