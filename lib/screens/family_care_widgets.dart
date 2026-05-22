import 'dart:async';

import 'package:chartjs_flutter/chartjs_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n/app_localizations.dart';
import '../config/app_env.dart';
import '../models/aisee_care_models.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';

Map<String, dynamic> careReportTotalsBarChartConfig(
  CareReportTotals t,
  AppLocalizations l,
) {
  return <String, dynamic>{
    'type': 'bar',
    'data': <String, dynamic>{
      'labels': <String>[
        l.careReportBarMedsActive,
        l.careReportBarTaken,
        l.careReportBarSkipped,
        l.careReportBarSymptoms,
        l.careReportBarMetrics,
        l.careReportBarSOS,
      ],
      'datasets': <Map<String, dynamic>>[
        <String, dynamic>{
          'label': l.careReportChartLabel,
          'data': <int>[
            t.activeMedications,
            t.takenMedications,
            t.skippedMedications,
            t.symptomCount,
            t.metricCount,
            t.sosAlertCount,
          ],
          'backgroundColor': <String>[
            'rgba(106, 27, 154, 0.72)',
            'rgba(46, 125, 50, 0.72)',
            'rgba(230, 81, 0, 0.72)',
            'rgba(198, 40, 40, 0.68)',
            'rgba(26, 50, 99, 0.72)',
            'rgba(194, 24, 91, 0.72)',
          ],
          'borderRadius': 8,
          'barThickness': 22,
        },
      ],
    },
    'options': <String, dynamic>{
      'responsive': true,
      'maintainAspectRatio': false,
      'plugins': <String, dynamic>{
        'legend': <String, bool>{'display': false},
      },
      'scales': <String, dynamic>{
        'x': <String, dynamic>{
          'grid': <String, bool>{'display': false},
          'ticks': <String, dynamic>{
            'font': <String, int>{'size': 10},
            'maxRotation': 0,
            'minRotation': 0,
          },
        },
        'y': <String, dynamic>{
          'beginAtZero': true,
          'ticks': <String, dynamic>{'precision': 0},
        },
      },
    },
  };
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ChartJsWidget(
              chartConfig: careReportTotalsBarChartConfig(totals, l),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.careWidgetDataTable,
            style: GoogleFonts.plusJakartaSans(
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

class _CareTotalsTable extends StatelessWidget {
  const _CareTotalsTable({required this.totals, required this.l});

  final CareReportTotals totals;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final TextStyle headerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: StyleTokens.textSecondary,
    );
    final TextStyle cellStyle = GoogleFonts.plusJakartaSans(
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
            style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                      height: 1.4,
                      color: StyleTokens.buttonPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.plusJakartaSans(
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.careWidgetWebReportsHint,
            style: GoogleFonts.plusJakartaSans(
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
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
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
                      style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
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
        style: GoogleFonts.plusJakartaSans(
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
    final TextStyle headerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: StyleTokens.textSecondary,
    );
    final TextStyle cellStyle = GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
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
