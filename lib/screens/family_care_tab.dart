import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_care_models.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_care_service.dart';
import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import 'family_care_pages.dart' show CareDailyBriefPage;
import 'family_care_support.dart';
import 'family_care_widgets.dart';

/// Tab Chăm sóc — hub Care MVP (biểu đồ + bảng) + cảnh báo + việc cần làm.
class FamilyCareTab extends StatefulWidget {
  const FamilyCareTab({
    required this.accessToken,
    required this.caredUserId,
    super.key,
  });

  final String accessToken;
  final String caredUserId;

  @override
  State<FamilyCareTab> createState() => _FamilyCareTabState();
}

class _FamilyCareTabState extends State<FamilyCareTab> {
  final AiseeCareService _care = AiseeCareService();
  CareDailyBriefResponse? _brief;
  List<CareAlert> _alerts = <CareAlert>[];
  List<CareTask> _tasks = <CareTask>[];
  bool _loadingBrief = true;
  bool _loadingAlerts = true;
  bool _loadingTasks = true;
  String? _briefError;
  String? _alertsError;
  String? _tasksError;
  Object? _briefException;

  @override
  void dispose() {
    _care.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await Future.wait(<Future<void>>[
      _loadBrief(),
      _loadAlerts(),
      _loadTasks(),
    ]);
  }

  Future<void> _loadBrief() async {
    setState(() {
      _loadingBrief = true;
      _briefError = null;
      _briefException = null;
    });
    try {
      final CareDailyBriefResponse b = await _care.getDailyBrief(
        widget.accessToken,
        widget.caredUserId,
      );
      if (!mounted) return;
      setState(() {
        _brief = b;
        _loadingBrief = false;
        _briefError = null;
        _briefException = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _brief = null;
        _loadingBrief = false;
        _briefError = e.toString();
        _briefException = e;
      });
    }
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loadingAlerts = true;
      _alertsError = null;
    });
    try {
      final List<CareAlert> list = await _care.listAlerts(
        widget.accessToken,
        widget.caredUserId,
        limit: 30,
      );
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _loadingAlerts = false;
        _alertsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alerts = <CareAlert>[];
        _loadingAlerts = false;
        _alertsError = e.toString();
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loadingTasks = true;
      _tasksError = null;
    });
    try {
      final List<CareTask> list = await _care.listTasks(
        widget.accessToken,
        widget.caredUserId,
      );
      if (!mounted) return;
      setState(() {
        _tasks = list;
        _loadingTasks = false;
        _tasksError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks = <CareTask>[];
        _loadingTasks = false;
        _tasksError = e.toString();
      });
    }
  }

  void _openBrief() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CareDailyBriefPage(
          accessToken: widget.accessToken,
          caredUserId: widget.caredUserId,
        ),
      ),
    );
  }

  Future<void> _onBriefErrorAction() async {
    if (!mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final Object? err = _briefException;
    if (err != null) {
      await handleFamilyCareApiError(
        context,
        err,
        fallbackTitle: l.careDailySummaryFallback,
        caredUserId: widget.caredUserId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_briefError ?? l.careDailySummaryError)),
      );
    }
  }

  Future<void> _onAck(CareAlert a) async {
    try {
      await _care.ackAlert(widget.accessToken, a.id);
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.careAlertAcknowledged,
          parameters: <String, Object?>{'alert_id': a.id, 'rule': a.ruleCode},
        ),
      );
      await _loadAlerts();
      if (mounted) {
        AppToast.show(AppLocalizations.of(context).careAlertAcknowledged);
      }
    } catch (e) {
      if (mounted) {
        await handleFamilyCareApiError(
          context,
          e,
          caredUserId: widget.caredUserId,
        );
      }
    }
  }

  Future<void> _onResolve(CareAlert a) async {
    try {
      await _care.resolveAlert(widget.accessToken, a.id);
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.careAlertResolved,
          parameters: <String, Object?>{'alert_id': a.id},
        ),
      );
      await _loadAlerts();
      if (mounted) AppToast.show(AppLocalizations.of(context).careAlertClosed);
    } catch (e) {
      if (mounted) {
        await handleFamilyCareApiError(
          context,
          e,
          caredUserId: widget.caredUserId,
        );
      }
    }
  }

  Future<void> _onDismiss(CareAlert a) async {
    try {
      await _care.dismissAlert(widget.accessToken, a.id);
      await _loadAlerts();
      if (mounted) AppToast.show(AppLocalizations.of(context).careAlertSkipped);
    } catch (e) {
      if (mounted) {
        await handleFamilyCareApiError(
          context,
          e,
          caredUserId: widget.caredUserId,
        );
      }
    }
  }

  Future<void> _addTask() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String? title = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) {
        final TextEditingController c = TextEditingController();
        return AlertDialog(
          title: Text(l.careTaskDialogTitle),
          content: TextField(
            controller: c,
            decoration: InputDecoration(
              labelText: l.careTaskDialogContentLabel,
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: Text(l.careTaskDialogCreate),
            ),
          ],
        );
      },
    );
    if (title == null || title.isEmpty) return;
    try {
      await _care.createTask(
        widget.accessToken,
        widget.caredUserId,
        title: title,
      );
      await _loadTasks();
      if (mounted) {
        AppToast.show(AppLocalizations.of(context).careTaskCreatedToast);
      }
    } catch (e) {
      if (mounted) {
        await handleFamilyCareApiError(
          context,
          e,
          caredUserId: widget.caredUserId,
        );
      }
    }
  }

  Future<void> _completeTask(CareTask t) async {
    try {
      await _care.completeTask(widget.accessToken, t.id);
      await _loadTasks();
      if (mounted) {
        AppToast.show(AppLocalizations.of(context).careTaskCompletedToast);
      }
    } catch (e) {
      if (mounted) {
        await handleFamilyCareApiError(
          context,
          e,
          caredUserId: widget.caredUserId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return ColoredBox(
      color: StyleTokens.background,
      child: RefreshIndicator(
        color: StyleTokens.buttonPrimary,
        onRefresh: _reloadAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: <Widget>[
            Text(
              l.careTabIntroTitle,
              style: aiseeTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: StyleTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.careTabIntroSubtitle,
              style: aiseeTextStyle(
                fontSize: 13,
                height: 1.35,
                color: StyleTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (_loadingBrief)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_briefError != null)
              _ErrorCard(
                message: _briefError!,
                onRetry: _loadBrief,
                onBilling: _onBriefErrorAction,
              )
            else if (_brief != null) ...<Widget>[
              FamilyCareTotalsOverviewCard(
                dateLabel: _brief!.date,
                totals: _brief!.totals,
              ),
              FamilyCareSummaryLines(lines: _brief!.summary),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _openBrief,
                  child: Text(l.careOpenFullSummary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FamilyCareWebReportLinks(caredUserId: widget.caredUserId),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l.careAlertsHeading,
                    style: aiseeTextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadAlerts,
                  child: Text(l.careRefreshAction),
                ),
              ],
            ),
            if (_loadingAlerts)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_alertsError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _alertsError!,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    color: StyleTokens.textSecondary,
                  ),
                ),
              )
            else if (_alerts.isEmpty)
              Text(
                l.careNoAlerts,
                style: aiseeTextStyle(
                  color: StyleTokens.textSecondary,
                ),
              )
            else
              for (final CareAlert a in _alerts)
                FamilyCareAlertCard(
                  alert: a,
                  onAck: () => _onAck(a),
                  onResolve: () => _onResolve(a),
                  onDismiss: () => _onDismiss(a),
                ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l.careTasksHeading,
                    style: aiseeTextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(onPressed: _addTask, child: Text(l.careTasksAdd)),
                TextButton(
                  onPressed: _loadTasks,
                  child: Text(l.careRefreshAction),
                ),
              ],
            ),
            if (_loadingTasks)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tasksError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _tasksError!,
                  style: aiseeTextStyle(
                    fontSize: 13,
                    color: StyleTokens.textSecondary,
                  ),
                ),
              )
            else if (_tasks.isEmpty)
              Text(
                l.careNoTasks,
                style: aiseeTextStyle(
                  color: StyleTokens.textSecondary,
                ),
              )
            else
              FamilyCareTasksTable(tasks: _tasks, onComplete: _completeTask),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.onBilling,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBilling;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l.careSummaryLoadFail,
            style: aiseeTextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: aiseeTextStyle(
              fontSize: 13,
              color: StyleTokens.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l.careRetryAction),
              ),
              FilledButton(
                onPressed: onBilling,
                style: FilledButton.styleFrom(
                  backgroundColor: StyleTokens.buttonPrimary,
                ),
                child: Text(l.careOpenPlanQuota),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
