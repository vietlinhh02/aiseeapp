import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n/app_localizations.dart';
import '../config/app_env.dart';
import '../models/aisee_care_models.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

class _CareTotalsBarDatum {
  const _CareTotalsBarDatum({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

List<_CareTotalsBarDatum> _careReportTotalsBarData(
  CareReportTotals totals,
  AppLocalizations l,
) {
  return <_CareTotalsBarDatum>[
    _CareTotalsBarDatum(
      label: l.careReportBarMedsActive,
      value: totals.activeMedications,
      color: const Color(0xFF6A1B9A),
    ),
    _CareTotalsBarDatum(
      label: l.careReportBarTaken,
      value: totals.takenMedications,
      color: const Color(0xFF2E7D32),
    ),
    _CareTotalsBarDatum(
      label: l.careReportBarSkipped,
      value: totals.skippedMedications,
      color: const Color(0xFFE65100),
    ),
    _CareTotalsBarDatum(
      label: l.careReportBarSymptoms,
      value: totals.symptomCount,
      color: const Color(0xFFC62828),
    ),
    _CareTotalsBarDatum(
      label: l.careReportBarMetrics,
      value: totals.metricCount,
      color: const Color(0xFF1A3263),
    ),
    _CareTotalsBarDatum(
      label: l.careReportBarSOS,
      value: totals.sosAlertCount,
      color: const Color(0xFFC2185B),
    ),
  ];
}

class FamilyCareTotalsOverviewCard extends StatelessWidget {
  const FamilyCareTotalsOverviewCard({
    required this.dateLabel,
    required this.totals,
    super.key,
  });

  final String dateLabel;
  final CareReportTotals totals;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<_CareTotalsBarDatum> chartData = _careReportTotalsBarData(
      totals,
      l,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.careWidgetOverviewTitle(dateLabel),
            style: aiseeTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 220, child: _CareTotalsBarChart(data: chartData)),
          const SizedBox(height: 12),
          Text(
            l.careWidgetDataTable,
            style: aiseeTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _CareTotalsTable(totals: totals, l: l),
        ],
      ),
    );
  }
}

class _CareTotalsBarChart extends StatelessWidget {
  const _CareTotalsBarChart({required this.data});

  final List<_CareTotalsBarDatum> data;

  @override
  Widget build(BuildContext context) {
    final double maxY =
        data.fold<int>(
          0,
          (int acc, _CareTotalsBarDatum item) =>
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
              reservedSize: 44,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: SizedBox(
                    width: 56,
                    child: Text(
                      data[index].label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
        barGroups: List<BarChartGroupData>.generate(data.length, (int index) {
          final _CareTotalsBarDatum item = data[index];
          return BarChartGroupData(
            x: index,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: item.value.toDouble(),
                width: 22,
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

class _CareTotalsTable extends StatelessWidget {
  const _CareTotalsTable({required this.totals, required this.l});

  final CareReportTotals totals;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = aiseeTextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: StyleTokens.textSecondary,
    );
    final TextStyle cellStyle = aiseeTextStyle(
      fontSize: 14,
      color: StyleTokens.textPrimary,
    );
    final Color line = StyleTokens.cardBorder;
    return Table(
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(2.4),
        1: FlexColumnWidth(1),
      },
      border: TableBorder(
        top: BorderSide(color: line),
        bottom: BorderSide(color: line),
        horizontalInside: BorderSide(color: line.withValues(alpha: 0.65)),
        verticalInside: BorderSide(color: line.withValues(alpha: 0.65)),
      ),
      children: <TableRow>[
        TableRow(
          decoration: BoxDecoration(color: StyleTokens.background),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(l.careWidgetCategoryCol, style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                l.careWidgetValueCol,
                textAlign: TextAlign.right,
                style: headerStyle,
              ),
            ),
          ],
        ),
        _row(l.careWidgetActiveMeds, '${totals.activeMedications}', cellStyle),
        _row(l.careWidgetDosesTaken, '${totals.takenMedications}', cellStyle),
        _row(
          l.careWidgetDosesSkipped,
          '${totals.skippedMedications}',
          cellStyle,
        ),
        _row(l.careWidgetSymptomLogs, '${totals.symptomCount}', cellStyle),
        _row(l.careWidgetMetricLogs, '${totals.metricCount}', cellStyle),
        _row(l.careWidgetSOSEvents, '${totals.sosAlertCount}', cellStyle),
        _row(l.careWidgetEscalations, '${totals.escalationCount}', cellStyle),
        _row(l.careWidgetVideoCalls, '${totals.videoCallCount}', cellStyle),
        _row(
          l.careWidgetVideoCallMinutes,
          totals.videoCallMinutes.toStringAsFixed(1),
          cellStyle,
        ),
        _row(
          l.careWidgetVoiceCallMinutes,
          totals.voiceCallMinutes.toStringAsFixed(1),
          cellStyle,
        ),
      ],
    );
  }

  TableRow _row(String label, String value, TextStyle cellStyle) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(label, style: cellStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(value, textAlign: TextAlign.right, style: cellStyle),
        ),
      ],
    );
  }
}

class FamilyCareSummaryLines extends StatelessWidget {
  const FamilyCareSummaryLines({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).careWidgetAutoNotes,
            style: aiseeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final String line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '• ',
                    style: aiseeTextStyle(
                      height: 1.4,
                      color: StyleTokens.buttonPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: aiseeTextStyle(
                        height: 1.4,
                        fontSize: 13,
                        color: StyleTokens.textPrimary,
                      ),
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

class FamilyCareWebReportLinks extends StatelessWidget {
  const FamilyCareWebReportLinks({required this.caredUserId, super.key});

  final String caredUserId;

  Future<void> _open(BuildContext context, String section) async {
    final Uri uri = AppEnv.familyCareWebUri(caredUserId, section);
    final bool ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      AppToast.show(AppLocalizations.of(context).careWidgetBrowserError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.careWidgetWebReportsTitle,
            style: aiseeTextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.careWidgetWebReportsHint,
            style: aiseeTextStyle(
              fontSize: 12,
              height: 1.35,
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _actionChip(
                l.careWebTimeline,
                () => unawaited(_open(context, 'timeline')),
              ),
              _actionChip(
                l.careWebWeekly,
                () => unawaited(_open(context, 'weekly')),
              ),
              _actionChip(
                l.careWebIncident,
                () => unawaited(_open(context, 'incident')),
              ),
              _actionChip(
                l.careWebExport,
                () => unawaited(_open(context, 'export')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: StyleTokens.textPrimary,
        side: BorderSide(color: StyleTokens.cardBorder),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: aiseeTextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

Color _severityColor(String severity) {
  final String s = severity.toLowerCase();
  if (s == 'critical' || s == 'severe') {
    return const Color(0xFFC62828);
  }
  if (s == 'warning') {
    return const Color(0xFFE65100);
  }
  return StyleTokens.buttonPrimary;
}

class FamilyCareAlertCard extends StatelessWidget {
  const FamilyCareAlertCard({
    required this.alert,
    required this.onAck,
    required this.onResolve,
    required this.onDismiss,
    super.key,
  });

  final CareAlert alert;
  final VoidCallback onAck;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Color accent = _severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: StyleTokens.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      alert.title,
                      style: aiseeTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: StyleTokens.textPrimary,
                      ),
                    ),
                    if (alert.body != null &&
                        alert.body!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        alert.body!,
                        style: aiseeTextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: StyleTokens.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: <Widget>[
                        _pill(l.careAlertPillLevel, alert.severity),
                        _pill(l.careAlertPillStatus, alert.status),
                        _pill(l.careAlertPillCode, alert.ruleCode),
                        _pill(
                          l.careAlertPillTime,
                          '${alert.createdAt.toLocal().day}/'
                          '${alert.createdAt.toLocal().month} '
                          '${alert.createdAt.toLocal().hour}:'
                          '${alert.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        if (alert.status == 'open')
                          TextButton(
                            onPressed: onAck,
                            child: Text(l.careAlertSeen),
                          ),
                        if (alert.status == 'open' ||
                            alert.status == 'acknowledged')
                          TextButton(
                            onPressed: onResolve,
                            child: Text(l.careAlertClose),
                          ),
                        if (alert.status != 'resolved' &&
                            alert.status != 'dismissed')
                          TextButton(
                            onPressed: onDismiss,
                            child: Text(l.careAlertSkip),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StyleTokens.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Text(
        '$k: $v',
        style: aiseeTextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: StyleTokens.textSecondary,
        ),
      ),
    );
  }
}

class FamilyCareTasksTable extends StatelessWidget {
  const FamilyCareTasksTable({
    required this.tasks,
    required this.onComplete,
    super.key,
  });

  final List<CareTask> tasks;
  final void Function(CareTask) onComplete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final TextStyle headerStyle = aiseeTextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: StyleTokens.textSecondary,
    );
    final TextStyle cellStyle = aiseeTextStyle(
      fontSize: 13,
      color: StyleTokens.textPrimary,
    );
    final Color line = StyleTokens.cardBorder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(0.9),
          3: FlexColumnWidth(0.75),
        },
        border: TableBorder(
          top: BorderSide(color: line),
          bottom: BorderSide(color: line),
          horizontalInside: BorderSide(color: line.withValues(alpha: 0.65)),
          verticalInside: BorderSide(color: line.withValues(alpha: 0.65)),
        ),
        children: <TableRow>[
          TableRow(
            decoration: BoxDecoration(color: StyleTokens.background),
            children: <Widget>[
              _cellPad(Text(l.careTaskColumnTask, style: headerStyle)),
              _cellPad(Text(l.careTaskColumnDue, style: headerStyle)),
              _cellPad(Text(l.careTaskColumnStatus, style: headerStyle)),
              _cellPad(Text(l.careTaskColumnAction, style: headerStyle)),
            ],
          ),
          for (final CareTask t in tasks)
            TableRow(
              children: <Widget>[
                _cellPad(
                  Text(
                    t.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: aiseeTextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ),
                _cellPad(
                  Text(
                    t.dueAt != null
                        ? '${t.dueAt!.toLocal().day}/${t.dueAt!.toLocal().month} '
                              '${t.dueAt!.toLocal().hour}:'
                              '${t.dueAt!.toLocal().minute.toString().padLeft(2, '0')}'
                        : '—',
                    style: cellStyle,
                  ),
                ),
                _cellPad(Text(t.status, style: cellStyle)),
                _cellPad(
                  t.status == 'open'
                      ? TextButton(
                          onPressed: () => onComplete(t),
                          child: Text(l.careTaskDone),
                        )
                      : Text('—', style: cellStyle),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Widget _cellPad(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: child,
    );
  }
}
