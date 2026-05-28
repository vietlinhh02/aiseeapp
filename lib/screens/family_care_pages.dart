import 'dart:async';

import 'dart:convert';


import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:aiseeapp/theme/aisee_typography.dart';


import '../generated/l10n/app_localizations.dart';

import '../models/aisee_care_models.dart';

import '../services/aisee_analytics_service.dart';

import '../services/aisee_care_service.dart';

import '../theme/style_tokens.dart';

import '../utils/app_toast.dart';

import 'family_care_support.dart';
import '../widgets/app_loading_indicator.dart';


String _ymd(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class CareTimelinePage extends StatefulWidget {
  const CareTimelinePage({
    required this.accessToken,
    required this.caredUserId,
    super.key,
  });

  final String accessToken;
  final String caredUserId;

  @override
  State<CareTimelinePage> createState() => _CareTimelinePageState();
}

class _CareTimelinePageState extends State<CareTimelinePage> {
  final AiseeCareService _care = AiseeCareService();
  CareTimelineResponse? _data;
  bool _loading = true;
  Object? _error;

  @override
  void dispose() {
    _care.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final CareTimelineResponse r = await _care.getTimeline(
        widget.accessToken,
        widget.caredUserId,
      );
      if (!mounted) return;
      setState(() {
        _data = r;
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
        title: Text(
          l.careTimelineTitle,
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: StyleTokens.background,
        elevation: 0,
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
            height: 120,
            child: AppLoadingIndicator(),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_error.toString(), style: StyleTokens.bodySmall()),
          TextButton(
            onPressed: () => handleFamilyCareApiError(
              context,
              _error!,
              fallbackTitle: l.careTimelineFallback,
              caredUserId: widget.caredUserId,
            ),
            child: Text(l.careViewPlanAction),
          ),
        ],
      );
    }
    final CareTimelineResponse d = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (d.effectiveDays < d.requestedDays)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.careTimelinePlanHint(d.effectiveDays, d.requestedDays),
              style: aiseeTextStyle(
                fontSize: 13,
                color: StyleTokens.textSecondary,
              ),
            ),
          ),
        if (d.events.isEmpty)
          Text(
            l.careTimelineEmpty,
            style: aiseeTextStyle(
              color: StyleTokens.textSecondary,
            ),
          ),
        for (final CareTimelineEvent e in d.events)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                e.title,
                style: aiseeTextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${e.kind}\n${e.detail ?? ''}\n${_ymd(e.occurredAt)}',
                style: aiseeTextStyle(fontSize: 13, height: 1.35),
              ),
            ),
          ),
      ],
    );
  }
}

class CareDailyBriefPage extends StatefulWidget {
  const CareDailyBriefPage({
    required this.accessToken,
    required this.caredUserId,
    super.key,
  });

  final String accessToken;
  final String caredUserId;

  @override
  State<CareDailyBriefPage> createState() => _CareDailyBriefPageState();
}

class _CareDailyBriefPageState extends State<CareDailyBriefPage> {
  final AiseeCareService _care = AiseeCareService();
  CareDailyBriefResponse? _data;
  bool _loading = true;
  Object? _error;
  DateTime _day = DateTime.now();

  @override
  void dispose() {
    _care.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final CareDailyBriefResponse r = await _care.getDailyBrief(
        widget.accessToken,
        widget.caredUserId,
        date: _ymd(_day),
      );
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
      });
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.dailyBriefOpened,
          parameters: <String, Object?>{'cared_user_id': widget.caredUserId},
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickDay() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _day = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        title: Text(
          l.careDailyBriefTitle,
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: StyleTokens.background,
        actions: <Widget>[
          TextButton(onPressed: _pickDay, child: Text(_ymd(_day))),
        ],
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
            height: 120,
            child: AppLoadingIndicator(),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_error.toString()),
          TextButton(
            onPressed: () => handleFamilyCareApiError(
              context,
              _error!,
              fallbackTitle: l.careDailyBriefTitle,
              caredUserId: widget.caredUserId,
            ),
            child: Text(l.careViewPlanAction),
          ),
        ],
      );
    }
    final CareDailyBriefResponse d = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l.careDailyBriefDate(d.date),
          style: aiseeTextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        for (final String line in d.summary)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $line',
              style: aiseeTextStyle(height: 1.4),
            ),
          ),
        const SizedBox(height: 16),
        _TotalsCard(totals: d.totals, l: l),
      ],
    );
  }
}

class CareWeeklyReportPage extends StatefulWidget {
  const CareWeeklyReportPage({
    required this.accessToken,
    required this.caredUserId,
    super.key,
  });

  final String accessToken;
  final String caredUserId;

  @override
  State<CareWeeklyReportPage> createState() => _CareWeeklyReportPageState();
}

class _CareWeeklyReportPageState extends State<CareWeeklyReportPage> {
  final AiseeCareService _care = AiseeCareService();
  CareWeeklyReportResponse? _data;
  bool _loading = true;
  Object? _error;
  DateTime _end = DateTime.now();

  @override
  void dispose() {
    _care.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final CareWeeklyReportResponse r = await _care.getWeeklyReport(
        widget.accessToken,
        widget.caredUserId,
        endDate: _ymd(_end),
      );
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
      });
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.weeklyReportOpened,
          parameters: <String, Object?>{'cared_user_id': widget.caredUserId},
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickEnd() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime.now().subtract(const Duration(days: 400)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _end = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        title: Text(
          l.careWeeklyReportTitle,
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: StyleTokens.background,
        actions: <Widget>[
          TextButton(
            onPressed: _pickEnd,
            child: Text(l.careWeeklyReportPickEnd),
          ),
        ],
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
            height: 120,
            child: AppLoadingIndicator(),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_error.toString()),
          TextButton(
            onPressed: () => handleFamilyCareApiError(
              context,
              _error!,
              fallbackTitle: l.careWeeklyReportTitle,
              caredUserId: widget.caredUserId,
            ),
            child: Text(l.careViewPlanAction),
          ),
        ],
      );
    }
    final CareWeeklyReportResponse d = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          '${d.startDate} → ${d.endDate}',
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final String line in d.summary)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• $line',
              style: aiseeTextStyle(height: 1.4),
            ),
          ),
        const SizedBox(height: 16),
        _TotalsCard(totals: d.totals, l: l),
      ],
    );
  }
}

class CareIncidentPage extends StatefulWidget {
  const CareIncidentPage({
    required this.accessToken,
    required this.caredUserId,
    super.key,
  });

  final String accessToken;
  final String caredUserId;

  @override
  State<CareIncidentPage> createState() => _CareIncidentPageState();
}

class _CareIncidentPageState extends State<CareIncidentPage> {
  final AiseeCareService _care = AiseeCareService();
  CareIncidentReportResponse? _data;
  bool _loading = true;
  Object? _error;

  @override
  void dispose() {
    _care.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final CareIncidentReportResponse r = await _care.getIncidentReport(
        widget.accessToken,
        widget.caredUserId,
      );
      if (!mounted) return;
      setState(() {
        _data = r;
        _loading = false;
      });
      unawaited(
        AiseeAnalyticsService.instance.track(
          AiseeAnalyticsEvent.incidentReportOpened,
          parameters: <String, Object?>{'cared_user_id': widget.caredUserId},
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  String _incidentText(CareIncidentReportResponse d, AppLocalizations l) {
    final StringBuffer b = StringBuffer();
    b.writeln(l.careIncidentTime(d.alertAt.toIso8601String()));
    b.writeln(l.careIncidentFamilyNotified(d.familyNotified));
    for (final CareIncidentEscalation e in d.escalations) {
      b.writeln('- ${e.status} ${e.contactName ?? ''} ${e.tried ?? ''}');
    }
    for (final String s in d.summary) {
      b.writeln(s);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        title: Text(
          l.careIncidentTitle,
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: StyleTokens.background,
        actions: <Widget>[
          if (_data != null)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: _incidentText(_data!, l)),
                );
                if (context.mounted) AppToast.show(l.careExportCopied);
              },
              child: Text(l.careExportCopyAction),
            ),
        ],
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
            height: 120,
            child: AppLoadingIndicator(),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(_error.toString()),
          TextButton(
            onPressed: () => handleFamilyCareApiError(
              context,
              _error!,
              fallbackTitle: l.careExportFallback,
              caredUserId: widget.caredUserId,
            ),
            child: Text(l.careViewPlanAction),
          ),
        ],
      );
    }
    final CareIncidentReportResponse d = _data!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          l.careIncidentAlertTime(d.alertAt.toLocal()),
          style: aiseeTextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(l.careIncidentLocation(d.location.lat, d.location.lng)),
        const SizedBox(height: 16),
        for (final String s in d.summary)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(s, style: aiseeTextStyle(height: 1.4)),
          ),
        const SizedBox(height: 12),
        for (final CareIncidentEscalation e in d.escalations)
          Card(
            child: ListTile(
              title: Text(e.status),
              subtitle: Text(
                '${e.contactName ?? ''}\n${e.tried ?? ''}\n${e.remaining?.join(", ") ?? ''}',
              ),
            ),
          ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals, required this.l});

  final CareReportTotals totals;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.careTotalsOverview,
              style: aiseeTextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(l.careTotalsActiveMeds(totals.activeMedications)),
            Text(
              l.careTotalsTakenSkipped(
                totals.skippedMedications,
                totals.takenMedications,
              ),
            ),
            Text(l.careTotalsSymptoms(totals.metricCount, totals.symptomCount)),
            Text(l.careTotalsSOS(totals.escalationCount, totals.sosAlertCount)),
            Text(
              l.careTotalsCalls(
                totals.videoCallCount,
                totals.videoCallMinutes,
                totals.voiceCallMinutes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> runCareExport(
  BuildContext context, {
  required AiseeCareService care,
  required String accessToken,
  required String caredUserId,
  required String reportType,
  String? date,
  String? endDate,
}) async {
  final AppLocalizations l = AppLocalizations.of(context);
  try {
    final CareExportResponse res = await care.exportPdf(
      accessToken,
      caredUserId,
      reportType: reportType,
      date: date,
      endDate: endDate,
    );
    unawaited(
      AiseeAnalyticsService.instance.track(
        AiseeAnalyticsEvent.careExportRequested,
        parameters: <String, Object?>{
          'report_type': reportType,
          'format': res.format,
          'cared_user_id': caredUserId,
        },
      ),
    );
    if (!context.mounted) return;
    final Object? rawData = res.data;
    final String payload = rawData == null
        ? l.careExportNoData
        : const JsonEncoder.withIndent('  ').convert(rawData);
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.careExportTitle),
        content: SingleChildScrollView(
          child: SelectableText(
            l.careExportFormat(res.format, res.exportId) + payload,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) AppToast.show(l.careExportCopied);
            },
            child: Text(l.careExportCopyAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.careExportClose),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      await handleFamilyCareApiError(
        context,
        e,
        fallbackTitle: l.careExportFallback,
        caredUserId: caredUserId,
      );
    }
  }
}
