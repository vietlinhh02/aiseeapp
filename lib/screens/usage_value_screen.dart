import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:intl/intl.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_api_models.dart';
import '../models/aisee_billing_models.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_billing_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'subscription_screen.dart';

class UsageValueScreen extends StatefulWidget {
  const UsageValueScreen({
    super.key,
    this.caredUserId,
    this.billingService,
    this.readTokens,
  });

  final String? caredUserId;
  final AiseeBillingService? billingService;
  final Future<AiseeAuthTokens?> Function()? readTokens;

  @override
  State<UsageValueScreen> createState() => _UsageValueScreenState();
}

class _UsageValueScreenState extends State<UsageValueScreen> {
  late final AiseeBillingService _billing;
  late final Future<AiseeAuthTokens?> Function() _readTokens;
  late final bool _ownsBillingService;

  AiseeBillingOverview? _overview;
  AiseeMeUsageResponse? _usageDetail;
  bool _loading = true;
  Object? _error;
  bool _showActionDetails = false;
  bool _showFeatureDetails = false;

  @override
  void initState() {
    super.initState();
    _billing = widget.billingService ?? AiseeBillingService();
    _readTokens = widget.readTokens ?? AiseeSessionStore.instance.read;
    _ownsBillingService = widget.billingService == null;
    unawaited(AiseeAnalyticsService.instance.trackScreen('usage_value'));
    unawaited(
      AiseeAnalyticsService.instance.track(
        AiseeAnalyticsEvent.usageValueOpened,
        parameters: const <String, Object?>{'source': 'usage_value_screen'},
      ),
    );
    _load();
  }

  @override
  void dispose() {
    if (_ownsBillingService) {
      _billing.close();
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
        throw AiseeApiException('__usage_session_expired__');
      }
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _billing.fetchBillingOverview(
          tokens.accessToken,
          caredUserId: widget.caredUserId,
        ),
        _billing.fetchUsage(
          tokens.accessToken,
          caredUserId: widget.caredUserId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as AiseeBillingOverview;
        _usageDetail = results[1] as AiseeMeUsageResponse;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        backgroundColor: StyleTokens.background,
        elevation: 0,
        title: Text(
          _screenTitle(l),
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l)),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_errorMessage(l, _error!), style: StyleTokens.bodySmall()),
          TextButton(onPressed: _load, child: Text(l.actionRetry)),
        ],
      );
    }

    final AiseeBillingOverview overview = _overview!;
    final AiseeMeUsageResponse? usage = _usageDetail;
    final Map<String, AiseeUsageQuota> quotas =
        usage?.quotas ?? overview.usage.quotas;
    final List<AiseeUsageQuota> callQuotas =
        quotas.values.where(_isCallQuota).toList()..sort(
          (a, b) => _quotaLabel(
            a.usageType,
            l,
          ).compareTo(_quotaLabel(b.usageType, l)),
        );
    final List<AiseeUsageQuota> mainQuotas =
        quotas.values
            .where((AiseeUsageQuota quota) => !_isCallQuota(quota))
            .toList()
          ..sort(_compareQuotaCards);
    final List<MapEntry<String, AiseeEntitlementValue>> enabledEntitlements =
        overview.entitlements.entries
            .where(
              (MapEntry<String, AiseeEntitlementValue> entry) =>
                  entry.value.enabled,
            )
            .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: <Widget>[
        _UsageHeaderCard(overview: overview, usage: usage, l: l),
        const SizedBox(height: 16),
        if (mainQuotas.isEmpty && callQuotas.isEmpty)
          _EmptyUsageCard(l: l)
        else ...<Widget>[
          for (final AiseeUsageQuota quota in mainQuotas) ...<Widget>[
            _UsageQuotaCard(quota: quota, l: l),
            const SizedBox(height: 12),
          ],
          if (callQuotas.isNotEmpty) ...<Widget>[
            _CallsUsageCard(quotas: callQuotas, usage: usage, l: l),
            const SizedBox(height: 12),
          ],
        ],
        if (enabledEntitlements.isNotEmpty) ...<Widget>[
          _CollapsibleInfoCard(
            title: l.usageValueEntitlementsTitle,
            countLabel: enabledEntitlements.length.toString(),
            expanded: _showFeatureDetails,
            onToggle: () {
              setState(() => _showFeatureDetails = !_showFeatureDetails);
            },
            child: Column(
              children: <Widget>[
                for (
                  int i = 0;
                  i < enabledEntitlements.length;
                  i++
                ) ...<Widget>[
                  _EntitlementRow(
                    title: _humanizeEntitlementKey(
                      l,
                      enabledEntitlements[i].key,
                    ),
                  ),
                  if (i < enabledEntitlements.length - 1)
                    const Divider(height: 20, color: StyleTokens.cardBorder),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ActionCard(
          l: l,
          overview: overview,
          usage: usage,
          expanded: _showActionDetails,
          onToggle: () {
            setState(() => _showActionDetails = !_showActionDetails);
          },
          onOpenPlans: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SubscriptionScreen(
                  familyFirst: true,
                  caredUserId: widget.caredUserId,
                ),
              ),
            );
            unawaited(
              AiseeAnalyticsService.instance.track(
                AiseeAnalyticsEvent.upgradeClicked,
                parameters: <String, Object?>{
                  'source': 'usage_value_screen',
                  'cared_user_id': widget.caredUserId,
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UsageHeaderCard extends StatelessWidget {
  const _UsageHeaderCard({
    required this.overview,
    required this.usage,
    required this.l,
  });

  final AiseeBillingOverview overview;
  final AiseeMeUsageResponse? usage;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final String? updatedLabel = _updatedLabel(l, usage?.asOf);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _screenTitle(l),
                  style: aiseeTextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _usageHeaderDescription(l),
                  style: aiseeTextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: StyleTokens.textSecondary,
                  ),
                ),
                if (updatedLabel != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    updatedLabel,
                    style: aiseeTextStyle(
                      fontSize: 12,
                      color: StyleTokens.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              overview.effectivePlan.name,
              style: aiseeTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: StyleTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageQuotaCard extends StatelessWidget {
  const _UsageQuotaCard({required this.quota, required this.l});

  final AiseeUsageQuota quota;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final double percent = _quotaPercent(quota);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _quotaLabel(quota.usageType, l),
                  style: aiseeTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ),
              Text(
                quota.unlimited
                    ? l.usageValueUnlimited
                    : _percentUsedLabel(l, (percent * 100).round()),
                style: aiseeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: quota.unlimited ? null : percent.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StyleTokens.buttonPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallsUsageCard extends StatelessWidget {
  const _CallsUsageCard({
    required this.quotas,
    required this.usage,
    required this.l,
  });

  final List<AiseeUsageQuota> quotas;
  final AiseeMeUsageResponse? usage;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final AiseeUsageQuota primary = quotas.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _callsTitle(l),
                  style: aiseeTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ),
              if (quotas.length > 1)
                Text(
                  '+${quotas.length - 1}',
                  style: aiseeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textSecondary,
                  ),
                ),
              if (quotas.length > 1) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _callQuotaStatus(l, primary),
                  textAlign: TextAlign.right,
                  style: aiseeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: primary.unlimited
                  ? 1
                  : _quotaPercent(primary).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(
                StyleTokens.buttonPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleInfoCard extends StatelessWidget {
  const _CollapsibleInfoCard({
    required this.title,
    required this.countLabel,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String countLabel;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: aiseeTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    countLabel,
                    style: aiseeTextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: StyleTokens.textMuted,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 160),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.l,
    required this.overview,
    required this.usage,
    required this.expanded,
    required this.onToggle,
    required this.onOpenPlans,
  });

  final AppLocalizations l;
  final AiseeBillingOverview overview;
  final AiseeMeUsageResponse? usage;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenPlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton(
                  onPressed: onOpenPlans,
                  style: FilledButton.styleFrom(
                    backgroundColor: StyleTokens.buttonPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l.usageValueViewPlan),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onToggle,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: <Widget>[
                  _ActionDetailRow(
                    label: l.localeName.startsWith('vi')
                        ? 'Gói hiện tại'
                        : 'Current plan',
                    value: overview.effectivePlan.name,
                  ),
                  if (usage?.periodStart != null &&
                      usage?.periodEnd != null) ...<Widget>[
                    const SizedBox(height: 8),
                    _ActionDetailRow(
                      label: l.localeName.startsWith('vi') ? 'Chu kỳ' : 'Cycle',
                      value: _periodLabel(l, usage!),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 160),
          ),
        ],
      ),
    );
  }
}

class _ActionDetailRow extends StatelessWidget {
  const _ActionDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: aiseeTextStyle(
              fontSize: 12,
              color: StyleTokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: aiseeTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _EntitlementRow extends StatelessWidget {
  const _EntitlementRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: StyleTokens.buttonPrimary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
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
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyUsageCard extends StatelessWidget {
  const _EmptyUsageCard({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        l.usageValueUnlimited,
        style: aiseeTextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: StyleTokens.textPrimary,
        ),
      ),
    );
  }
}

String _errorMessage(AppLocalizations l, Object error) {
  if (error is AiseeApiException &&
      error.message == '__usage_session_expired__') {
    return l.usageValueSessionExpired;
  }
  if (error is AiseeApiException) {
    return error.message;
  }
  return error.toString();
}

bool _isCallQuota(AiseeUsageQuota quota) {
  return quota.usageType == 'voice_call_minutes' ||
      quota.usageType == 'video_call_minutes' ||
      quota.usageType == 'voice_calls' ||
      quota.usageType == 'video_calls' ||
      quota.usageType == 'voice_calls_enabled' ||
      quota.usageType == 'video_calls_enabled';
}

int _compareQuotaCards(AiseeUsageQuota a, AiseeUsageQuota b) {
  final int resetCompare = _quotaPeriodRank(
    a.resetPeriod,
  ).compareTo(_quotaPeriodRank(b.resetPeriod));
  if (resetCompare != 0) return resetCompare;
  return _quotaLabel(a.usageType).compareTo(_quotaLabel(b.usageType));
}

int _quotaPeriodRank(String? resetPeriod) {
  switch ((resetPeriod ?? '').trim().toLowerCase()) {
    case 'day':
      return 0;
    case 'week':
      return 1;
    case 'month':
      return 2;
    default:
      return 3;
  }
}

double _quotaPercent(AiseeUsageQuota quota) {
  final double total = quota.limit + quota.granted;
  if (quota.unlimited || total <= 0) return 0;
  return quota.used / total;
}

String _screenTitle(AppLocalizations l) {
  if (l.localeName.startsWith('vi')) {
    return 'Hạn mức sử dụng';
  }
  return 'Usage limits';
}

String _usageHeaderDescription(AppLocalizations l) {
  if (l.localeName.startsWith('vi')) {
    return 'Phút AI, số lần bật camera và cuộc gọi đã dùng trong kỳ hiện tại. '
        'Các quyền chăm sóc đang bật theo gói.';
  }
  return 'AI minutes, camera activations and calls used this period. '
      'Active care features in your current plan.';
}

String? _updatedLabel(AppLocalizations l, DateTime? asOf) {
  if (asOf == null) return null;
  final String stamp = DateFormat('HH:mm').format(asOf.toLocal());
  return l.localeName.startsWith('vi')
      ? 'Vừa cập nhật lúc $stamp'
      : 'Updated at $stamp';
}

String _percentUsedLabel(AppLocalizations l, int percent) {
  return l.localeName.startsWith('vi')
      ? 'Đã sử dụng $percent%'
      : '$percent% used';
}

String _humanizeEntitlementKey(AppLocalizations l, String key) {
  switch (key) {
    case 'ai_minutes_per_month':
      return l.localeName.startsWith('vi')
          ? 'Phút AI mỗi tháng'
          : 'AI minutes per month';
    case 'camera_activations_per_day':
      return l.localeName.startsWith('vi')
          ? 'Lượt mở camera mỗi ngày'
          : 'Camera activations per day';
    case 'daily_brief_enabled':
      return l.localeName.startsWith('vi')
          ? 'Tóm tắt hằng ngày'
          : 'Daily brief';
    case 'weekly_report_enabled':
      return l.localeName.startsWith('vi') ? 'Báo cáo tuần' : 'Weekly report';
    case 'care_timeline_days':
      return l.localeName.startsWith('vi')
          ? 'Lịch sử chăm sóc'
          : 'Care timeline';
    case 'incident_report_enabled':
      return l.localeName.startsWith('vi')
          ? 'Báo cáo sự cố'
          : 'Incident report';
    case 'cared_users_limit':
      return l.localeName.startsWith('vi')
          ? 'Số người được chăm sóc'
          : 'Cared users limit';
    case 'csv_exports_per_month':
      return l.localeName.startsWith('vi')
          ? 'Xuất CSV mỗi tháng'
          : 'CSV exports per month';
    case 'export_format':
      return l.localeName.startsWith('vi')
          ? 'Định dạng xuất dữ liệu'
          : 'Export format';
    case 'family_members_limit':
      return l.localeName.startsWith('vi')
          ? 'Số người thân'
          : 'Family members limit';
    case 'medication_reminders_enabled':
      return l.localeName.startsWith('vi')
          ? 'Nhắc uống thuốc'
          : 'Medication reminders';
    case 'permission_matrix_level':
      return l.localeName.startsWith('vi')
          ? 'Mức phân quyền gia đình'
          : 'Permission matrix level';
    case 'read_messages_enabled':
      return l.localeName.startsWith('vi') ? 'Đọc tin nhắn' : 'Read messages';
    case 'smart_alert_enabled':
      return l.localeName.startsWith('vi')
          ? 'Cảnh báo thông minh'
          : 'Smart alerts';
    case 'sos_enabled':
      return l.localeName.startsWith('vi') ? 'Gọi khẩn cấp SOS' : 'SOS';
    case 'video_calls':
    case 'video_calls_enabled':
    case 'video_calls_per_day':
      return l.localeName.startsWith('vi')
          ? 'Cuộc gọi video mỗi ngày'
          : 'Video calls per day';
    case 'voice_calls':
    case 'voice_calls_enabled':
      return l.localeName.startsWith('vi') ? 'Cuộc gọi thoại' : 'Voice calls';
    case 'volunteer_priority_level':
      return l.localeName.startsWith('vi')
          ? 'Ưu tiên tình nguyện viên'
          : 'Volunteer priority';
    default:
      final String spaced = key.replaceAll('_', ' ').trim();
      if (spaced.isEmpty) return key;
      return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

String _quotaLabel(String usageType, [AppLocalizations? l]) {
  final bool isVi = l == null ? true : l.localeName.startsWith('vi');
  switch (usageType) {
    case 'ai_minutes':
    case 'ai_minutes_per_month':
      return isVi ? 'Phút AI' : 'AI minutes';
    case 'camera_activations':
    case 'camera_activations_per_day':
      return isVi ? 'Lượt camera' : 'Camera activations';
    case 'voice_call_minutes':
    case 'voice_calls':
    case 'voice_calls_enabled':
      return isVi ? 'Gọi thoại' : 'Voice calls';
    case 'video_call_minutes':
    case 'video_calls':
    case 'video_calls_enabled':
      return isVi ? 'Gọi video' : 'Video calls';
    case 'pdf_exports':
    case 'care_pdf_exports':
    case 'csv_exports_per_month':
      return isVi ? 'Xuất PDF' : 'PDF exports';
    case 'care_coach_questions':
      return isVi ? 'Câu hỏi chăm sóc' : 'Care questions';
    case 'pattern_detection_runs':
      return isVi ? 'Phân tích xu hướng' : 'Trend analysis';
    case 'weekly_report_enabled':
      return isVi ? 'Báo cáo tuần' : 'Weekly report';
    default:
      return usageType;
  }
}

String _callsTitle(AppLocalizations l) {
  return l.localeName.startsWith('vi') ? 'Cuộc gọi' : 'Calls';
}

String _callQuotaStatus(AppLocalizations l, AiseeUsageQuota quota) {
  if (quota.unlimited) {
    return l.usageValueUnlimited;
  }
  final String unit = (quota.unit ?? '').isEmpty ? 'phút' : quota.unit!;
  if (l.localeName.startsWith('vi')) {
    return 'Còn ${_trimNumber(quota.remaining)} $unit';
  }
  return '${_trimNumber(quota.remaining)} $unit left';
}

String _periodLabel(AppLocalizations l, AiseeMeUsageResponse usage) {
  final DateTime start = usage.periodStart!.toLocal();
  final DateTime end = usage.periodEnd!.toLocal();
  final String label =
      '${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}';
  if (l.localeName.startsWith('vi')) {
    return label;
  }
  return label;
}

String _trimNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}
