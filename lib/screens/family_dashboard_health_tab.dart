import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:aiseeapp/theme/aisee_typography.dart';


import '../models/aisee_dashboard_models.dart';

import '../theme/style_tokens.dart';

import '../generated/l10n/app_localizations.dart';

import 'family_dashboard_format.dart';
import '../widgets/app_loading_indicator.dart';


typedef HealthOverviewChartBuilder =
    Widget Function(HealthOverviewChartData chartData);

class HealthOverviewChartBar {
  const HealthOverviewChartBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class HealthOverviewChartData {
  const HealthOverviewChartData({required this.bars});

  final List<HealthOverviewChartBar> bars;
}

class FamilyDashboardHealthTab extends StatelessWidget {
  const FamilyDashboardHealthTab({
    required this.loading,
    required this.health,
    required this.onRefresh,
    this.overviewChartBuilder,
    super.key,
  });

  final bool loading;
  final DashboardHealth? health;
  final Future<void> Function() onRefresh;
  final HealthOverviewChartBuilder? overviewChartBuilder;

  static const String _icCalendar = 'assets/icons/nav/ic_calendar.svg';
  static const String _icActivity = 'assets/icons/nav/ic_activity.svg';
  static const String _icHeart = 'assets/icons/nav/ic_heart.svg';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (loading) {
      return const ColoredBox(
        color: StyleTokens.background,
        child: AppLoadingIndicator(),
      );
    }
    final h = health;
    if (h == null) {
      return ColoredBox(
        color: StyleTokens.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HealthNavIcon(
                  asset: _icHeart,
                  backgroundColor: StyleTokens.navInactivePill,
                  iconColor: StyleTokens.textMuted,
                  size: 56,
                  iconSize: 28,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.dashboardHealthNoData,
                  textAlign: TextAlign.center,
                  style: aiseeTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dashboardHealthPullToRefresh,
                  textAlign: TextAlign.center,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    color: StyleTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: StyleTokens.background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: StyleTokens.buttonPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              l10n.dashboardHealthTitle,
              style: aiseeTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: StyleTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.dashboardHealthSubtitle,
              style: aiseeTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: StyleTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _HealthOverviewCard(
              health: h,
              chartBuilder:
                  overviewChartBuilder ?? _defaultHealthOverviewChartBuilder,
            ),
            const SizedBox(height: 22),
            _HealthSectionHeader(
              title: l10n.dashboardHealthMedsToday,
              iconAsset: _icCalendar,
            ),
            const SizedBox(height: 10),
            if (h.medications.isEmpty)
              _HealthEmptyCard(
                message: l10n.dashboardHealthNoMeds,
                iconAsset: _icCalendar,
              )
            else
              ...h.medications.map(_MedAdherenceCard.new),
            const SizedBox(height: 22),
            _HealthSectionHeader(
              title: l10n.dashboardHealthRecentSymptoms,
              iconAsset: _icActivity,
            ),
            const SizedBox(height: 10),
            if (h.recentSymptoms.isEmpty)
              _HealthEmptyCard(
                message: l10n.dashboardHealthNoSymptoms,
                iconAsset: _icActivity,
              )
            else
              ...h.recentSymptoms.map(_SymptomCard.new),
            const SizedBox(height: 22),
            _HealthSectionHeader(
              title: l10n.dashboardHealthMetrics,
              iconAsset: _icHeart,
            ),
            const SizedBox(height: 10),
            if (h.recentMetrics.isEmpty)
              _HealthEmptyCard(
                message: l10n.dashboardHealthNoMetrics,
                iconAsset: _icHeart,
              )
            else
              ...h.recentMetrics.map(_MetricCard.new),
          ],
        ),
      ),
    );
  }
}

class _HealthSectionHeader extends StatelessWidget {
  const _HealthSectionHeader({required this.title, required this.iconAsset});

  final String title;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HealthNavIcon(
          asset: iconAsset,
          backgroundColor: StyleTokens.navInactivePill,
          iconColor: StyleTokens.buttonPrimary,
          size: 36,
          iconSize: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: aiseeTextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                decoration: BoxDecoration(
                  color: StyleTokens.buttonPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthNavIcon extends StatelessWidget {
  const _HealthNavIcon({
    required this.asset,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 48,
    this.iconSize = 24,
  });

  final String asset;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}

class _HealthEmptyCard extends StatelessWidget {
  const _HealthEmptyCard({required this.message, required this.iconAsset});

  final String message;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        children: [
          _HealthNavIcon(
            asset: iconAsset,
            backgroundColor: StyleTokens.background,
            iconColor: StyleTokens.textMuted,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: aiseeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: StyleTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthOverviewCard extends StatelessWidget {
  const _HealthOverviewCard({required this.health, required this.chartBuilder});

  final DashboardHealth health;
  final HealthOverviewChartBuilder chartBuilder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final takenCount = health.medications.where((m) => m.takenToday).length;
    final pendingCount = health.medications.length - takenCount;
    final symptomCount = health.recentSymptoms.length;
    final metricCount = health.recentMetrics.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardHealthOverview,
            style: aiseeTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: chartBuilder(
              _overviewChartConfig(
                l10n,
                takenCount: takenCount,
                pendingCount: pendingCount,
                symptomCount: symptomCount,
                metricCount: metricCount,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OverviewStatPill(
                label: l10n.dashboardHealthTakenToday,
                value: takenCount.toString(),
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF2E7D32),
              ),
              _OverviewStatPill(
                label: l10n.dashboardHealthNotTaken,
                value: pendingCount.toString(),
                backgroundColor: const Color(0xFFFFF3E0),
                foregroundColor: const Color(0xFFE65100),
              ),
              _OverviewStatPill(
                label: l10n.dashboardHealthSymptoms,
                value: symptomCount.toString(),
                backgroundColor: const Color(0xFFFFEBEE),
                foregroundColor: const Color(0xFFC62828),
              ),
              _OverviewStatPill(
                label: l10n.dashboardHealthMetricsPill,
                value: metricCount.toString(),
                backgroundColor: const Color(0xFFE3F2FD),
                foregroundColor: StyleTokens.buttonPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStatPill extends StatelessWidget {
  const _OverviewStatPill({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: aiseeTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _MedAdherenceCard extends StatelessWidget {
  const _MedAdherenceCard(this.m);

  static const String _icCalendar = 'assets/icons/nav/ic_calendar.svg';

  final MedWithAdherence m;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final taken = m.takenToday;
    final statusBg = taken ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final statusFg = taken ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final iconBg = taken ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final iconFg = taken ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthNavIcon(
            asset: _icCalendar,
            backgroundColor: iconBg,
            iconColor: iconFg,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        m.medication.name,
                        style: aiseeTextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: StyleTokens.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        taken
                            ? l10n.dashboardHealthTakenStatus
                            : l10n.dashboardHealthNotTakenStatus,
                        style: aiseeTextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  m.medication.dosage,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textSecondary,
                  ),
                ),
                if (m.medication.times.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    m.medication.times.join(' · '),
                    style: StyleTokens.bodySmall(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard(this.s);

  static const String _icActivity = 'assets/icons/nav/ic_activity.svg';

  final HealthSymptom s;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthNavIcon(
            asset: _icActivity,
            backgroundColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFE65100),
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.symptom,
                  style: aiseeTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (s.severity != null && s.severity!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.severity!.trim(),
                          style: aiseeTextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    Text(
                      formatFamilyDashboardTime(s.loggedAt),
                      style: aiseeTextStyle(
                        fontSize: 12,
                        color: StyleTokens.textSecondary,
                      ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.m);

  static const String _icProgress = 'assets/icons/nav/ic_progress.svg';

  final HealthMetric m;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HealthNavIcon(
            asset: _icProgress,
            backgroundColor: const Color(0xFFE3F2FD),
            iconColor: StyleTokens.buttonPrimary,
            size: 48,
            iconSize: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.metricType,
                  style: aiseeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.value}${m.unit != null && m.unit!.trim().isNotEmpty ? ' ${m.unit}' : ''}',
                  style: aiseeTextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatFamilyDashboardTime(m.loggedAt),
                  style: aiseeTextStyle(
                    fontSize: 12,
                    color: StyleTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _defaultHealthOverviewChartBuilder(HealthOverviewChartData chartData) {
  return _HealthOverviewBarChart(chartData: chartData);
}

HealthOverviewChartData _overviewChartConfig(
  AppLocalizations l10n, {
  required int takenCount,
  required int pendingCount,
  required int symptomCount,
  required int metricCount,
}) {
  return HealthOverviewChartData(
    bars: <HealthOverviewChartBar>[
      HealthOverviewChartBar(
        label: l10n.dashboardHealthTakenToday,
        value: takenCount,
        color: const Color(0xFF2E7D32),
      ),
      HealthOverviewChartBar(
        label: l10n.dashboardHealthNotTaken,
        value: pendingCount,
        color: const Color(0xFFE65100),
      ),
      HealthOverviewChartBar(
        label: l10n.dashboardHealthSymptoms,
        value: symptomCount,
        color: const Color(0xFFC62828),
      ),
      HealthOverviewChartBar(
        label: l10n.dashboardHealthMetricsPill,
        value: metricCount,
        color: StyleTokens.buttonPrimary,
      ),
    ],
  );
}

class _HealthOverviewBarChart extends StatelessWidget {
  const _HealthOverviewBarChart({required this.chartData});

  final HealthOverviewChartData chartData;

  @override
  Widget build(BuildContext context) {
    final double maxY =
        chartData.bars.fold<int>(
          0,
          (int acc, HealthOverviewChartBar item) =>
              item.value > acc ? item.value : acc,
        ) +
        1;

    return BarChart(
      BarChartData(
        maxY: maxY <= 1 ? 1 : maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (double value) => FlLine(
            color: StyleTokens.cardBorder.withValues(alpha: 0.6),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: aiseeTextStyle(
                    fontSize: 10,
                    color: StyleTokens.textMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= chartData.bars.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: SizedBox(
                    width: 58,
                    child: Text(
                      chartData.bars[index].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(chartData.bars.length, (
          int index,
        ) {
          final HealthOverviewChartBar item = chartData.bars[index];
          return BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: item.value.toDouble(),
                width: 28,
                color: item.color,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          );
        }),
      ),
    );
  }
}
