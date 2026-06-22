import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/services/aisee_analytics_service.dart';
import 'package:aiseeapp/services/aisee_reminders_data_provider.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:aiseeapp/theme/style_tokens.dart';
import 'package:aiseeapp/widgets/app_loading_indicator.dart';
import 'package:aiseeapp/widgets/reminders_detail_sheet.dart';

import '../models/aisee_api_models.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({
    super.key,
    this.initialFilter = ReminderFilter.all,
    this.highlightedReminderId,
  });

  final ReminderFilter initialFilter;
  final int? highlightedReminderId;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final AiseeRemindersDataProvider _dataProvider =
      AiseeRemindersDataProvider();

  List<Map<String, dynamic>> _medications = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _appointments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _healthLogs = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    unawaited(AiseeAnalyticsService.instance.trackScreen('reminders'));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final String? accessToken = await _dataProvider.accessToken();
    if (accessToken == null || !mounted) return;

    try {
      final ReminderFilter f = widget.initialFilter;
      if (f == ReminderFilter.all || f == ReminderFilter.medication) {
        _medications = await _dataProvider.fetchMedications(accessToken);
      }
      if (f == ReminderFilter.all || f == ReminderFilter.appointment) {
        _appointments = await _dataProvider.fetchAppointments(accessToken);
      }
      if (f == ReminderFilter.all || f == ReminderFilter.health) {
        _healthLogs = await _dataProvider.fetchHealthLogs(accessToken);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AiseeApiException ? e.message : l10n.remindersLoadFailed;
      });
    }
  }

  Future<void> _deleteReminder(Map<String, dynamic> item) async {
    final int? localId = item['local_id'] as int?;
    if (localId != null) {
      await _dataProvider.cancelReminder(localId);
    }
    await _load();
  }

  String get _title {
    return switch (widget.initialFilter) {
      ReminderFilter.medication => l10n.remindersMedication,
      ReminderFilter.appointment => l10n.personalAppointmentsTitle,
      ReminderFilter.health => l10n.personalHealthLogTitle,
      ReminderFilter.all => 'Reminders',
    };
  }

  Future<void> _markMedication(
    Map<String, dynamic> item, {
    required bool taken,
  }) async {
    final String? accessToken = await _dataProvider.accessToken();
    if (accessToken == null) return;
    try {
      final Map<String, dynamic> data = {
        'reminder_id': item['id'],
        'medication_name': AiseeRemindersDataProvider.itemTitle(item),
      };
      if (taken) {
        await _dataProvider.markMedicationTaken(accessToken, data);
        unawaited(
          AiseeAnalyticsService.instance.track(
            AiseeAnalyticsEvent.medicationTaken,
            parameters: <String, Object?>{'source': 'reminders'},
          ),
        );
      } else {
        await _dataProvider.markMedicationSkipped(accessToken, data);
        unawaited(
          AiseeAnalyticsService.instance.track(
            AiseeAnalyticsEvent.medicationSkipped,
            parameters: <String, Object?>{'source': 'reminders'},
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        backgroundColor: StyleTokens.background,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _title,
          style: aiseeTextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _loading
            ? const AppLoadingIndicator(key: ValueKey<String>('loading'))
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildStateMessage(
        key: const ValueKey<String>('error'),
        iconAsset: 'assets/icons/nav/ic_danger_circle.svg',
        message: _error!,
        actionLabel: l10n.remindersRetry,
        onAction: _load,
        color: StyleTokens.error,
      );
    }

    final ReminderFilter f = widget.initialFilter;

    if (f == ReminderFilter.health) {
      return _buildHealthSection();
    }

    final bool showMeds =
        f == ReminderFilter.all || f == ReminderFilter.medication;
    final bool showAppts =
        f == ReminderFilter.all || f == ReminderFilter.appointment;

    final List<Map<String, dynamic>> meds = showMeds
        ? _medications
        : <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> appts = showAppts
        ? _appointments
        : <Map<String, dynamic>>[];

    if (meds.isEmpty && appts.isEmpty) {
      return _buildEmpty();
    }

    return ListView(
      key: const ValueKey<String>('reminders'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: <Widget>[
        _summaryBand(
          primaryCount: meds.length,
          secondaryCount: appts.length,
          primaryLabel: l10n.remindersMedication,
          secondaryLabel: l10n.personalAppointmentsTitle,
        ),
        const SizedBox(height: 18),
        if (meds.isNotEmpty) ...<Widget>[
          _sectionHeader(
            l10n.personalMedicationTitle,
            'assets/icons/nav/ic_heart.svg',
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < meds.length; i++) ...<Widget>[
            _animatedListItem(
              index: i,
              child: _buildItemCard(meds[i], isMed: true),
            ),
            if (i < meds.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
        ],
        if (appts.isNotEmpty) ...<Widget>[
          _sectionHeader(
            l10n.personalAppointmentsTitle,
            'assets/icons/nav/ic_calendar.svg',
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < appts.length; i++) ...<Widget>[
            _animatedListItem(
              index: meds.length + i,
              child: _buildItemCard(appts[i], isMed: false),
            ),
            if (i < appts.length - 1) const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _summaryBand({
    required int primaryCount,
    required int secondaryCount,
    required String primaryLabel,
    required String secondaryLabel,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            _summaryMetric(primaryCount, primaryLabel),
            Container(
              width: 1,
              height: 34,
              color: StyleTokens.cardBorder,
              margin: const EdgeInsets.symmetric(horizontal: 14),
            ),
            _summaryMetric(secondaryCount, secondaryLabel),
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric(int count, String label) {
    return Expanded(
      child: Row(
        children: <Widget>[
          Text(
            count.toString(),
            style: aiseeTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: aiseeTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: StyleTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedListItem({required int index, required Widget child}) {
    final int cappedIndex = index.clamp(0, 8);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + cappedIndex * 35),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? item) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: item,
          ),
        );
      },
      child: child,
    );
  }

  Widget _sectionHeader(String title, String iconAsset) {
    return Row(
      children: <Widget>[
        SvgPicture.asset(
          iconAsset,
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(
            StyleTokens.buttonPrimary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: aiseeTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, {required bool isMed}) {
    final String title = AiseeRemindersDataProvider.itemTitle(item);
    final String subtitle = isMed
        ? AiseeRemindersDataProvider.medSubtitle(item, l10n)
        : AiseeRemindersDataProvider.apptSubtitle(item, l10n);
    final bool highlighted =
        item['id'] == widget.highlightedReminderId ||
        item['local_id'] == widget.highlightedReminderId;
    return Semantics(
      button: true,
      label: l10n.remindersDetailSemantics(title, subtitle),
      child: Material(
        color: highlighted ? const Color(0xFFEAF0FA) : StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showItemDetail(item, isMed: isMed),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                SvgPicture.asset(
                  isMed
                      ? 'assets/icons/nav/ic_heart.svg'
                      : 'assets/icons/nav/ic_calendar.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.buttonPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: aiseeTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: aiseeTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: StyleTokens.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/nav/ic_arrow_right.svg',
                  width: 10,
                  height: 10,
                  colorFilter: const ColorFilter.mode(
                    StyleTokens.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSection() {
    if (_healthLogs.isEmpty) return _buildHealthPlaceholder();
    return ListView(
      key: const ValueKey<String>('health'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: <Widget>[
        _summaryBand(
          primaryCount: _healthLogs.length,
          secondaryCount: 0,
          primaryLabel: l10n.personalHealthLogTitle,
          secondaryLabel: '0',
        ),
        const SizedBox(height: 18),
        _sectionHeader(
          l10n.personalHealthLogTitle,
          'assets/icons/nav/ic_activity.svg',
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _healthLogs.length; i++) ...<Widget>[
          _animatedListItem(
            index: i,
            child: _buildHealthLogCard(_healthLogs[i]),
          ),
          if (i < _healthLogs.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHealthLogCard(Map<String, dynamic> log) {
    final String kind = log['_kind'] as String? ?? '';
    final bool isSymptom = kind == 'symptom';
    final String desc = isSymptom
        ? (log['symptom'] as String? ?? '')
        : AiseeRemindersDataProvider.metricType(
            log['metric_type'] as String? ?? '',
            l10n,
          );
    final String severity = log['severity'] as String? ?? '';
    final String value = log['value']?.toString() ?? '';
    final String unit = log['unit'] as String? ?? '';
    final String notes = log['notes'] as String? ?? '';
    final String? loggedAt = log['logged_at'] as String?;
    String timeStr = '';
    if (loggedAt != null) {
      try {
        final DateTime dt = DateTime.parse(loggedAt).toLocal();
        timeStr =
            '${dt.day.toString().padLeft(2, '0')}/'
            '${dt.month.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    final String detail = isSymptom
        ? <String>[
            if (severity.isNotEmpty) severity,
            if (notes.isNotEmpty) notes,
            if (timeStr.isNotEmpty) timeStr,
          ].join(' · ')
        : <String>[
            if (value.isNotEmpty) '$value $unit'.trim(),
            if (timeStr.isNotEmpty) timeStr,
          ].join(' · ');
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/nav/ic_activity.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                StyleTokens.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    desc,
                    style: aiseeTextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                  if (detail.isNotEmpty) const SizedBox(height: 3),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: aiseeTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: StyleTokens.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: StyleTokens.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isSymptom ? l10n.healthSymptoms : l10n.healthMetrics,
                style: aiseeTextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: StyleTokens.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return _buildStateMessage(
      key: const ValueKey<String>('empty-reminders'),
      iconAsset: 'assets/icons/nav/ic_calendar.svg',
      message: l10n.remindersEmpty,
    );
  }

  Widget _buildHealthPlaceholder() {
    return _buildStateMessage(
      key: const ValueKey<String>('empty-health'),
      iconAsset: 'assets/icons/nav/ic_activity.svg',
      message: l10n.personalHealthLogSubtitle,
    );
  }

  Widget _buildStateMessage({
    required Key key,
    required String iconAsset,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Color color = StyleTokens.textMuted,
  }) {
    return Center(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            iconAsset,
            width: 36,
            height: 36,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: aiseeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: color,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  void _showItemDetail(Map<String, dynamic> item, {required bool isMed}) {
    RemindersDetailSheet.show(
      context,
      item: item,
      isMed: isMed,
      onTaken: () => _markMedication(item, taken: true),
      onSkipped: () => _markMedication(item, taken: false),
      onDelete: () => _deleteReminder(item),
    );
  }
}
