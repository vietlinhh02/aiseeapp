import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_api_models.dart';
import '../services/aisee_analytics_service.dart';
import '../services/aisee_health_service.dart';
import '../services/aisee_reminder_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';

enum ReminderFilter { all, medication, appointment, health }

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
  List<Map<String, dynamic>> _medications = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _appointments = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _healthLogs = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;

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
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) return;

    final AiseeHealthService svc = AiseeHealthService();
    try {
      final ReminderFilter f = widget.initialFilter;
      if (f == ReminderFilter.all || f == ReminderFilter.medication) {
        _medications = await svc.fetchMedications(tokens.accessToken);
      }
      if (f == ReminderFilter.all || f == ReminderFilter.appointment) {
        _appointments = await svc.fetchAppointments(tokens.accessToken);
      }
      if (f == ReminderFilter.all || f == ReminderFilter.health) {
        _healthLogs = await svc.fetchHealthLogs(tokens.accessToken);
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is AiseeApiException ? e.message : 'Không tải được dữ liệu.';
      });
    } finally {
      svc.close();
    }
  }

  Future<void> _deleteReminder(Map<String, dynamic> item) async {
    // Cancel local notification if exists.
    final int? localId = item['local_id'] as int?;
    if (localId != null) {
      await AiseeReminderService.instance.cancelReminder(localId);
    }
    await _load();
  }

  String get _title {
    switch (widget.initialFilter) {
      case ReminderFilter.medication:
        return 'Lịch uống thuốc';
      case ReminderFilter.appointment:
        return 'Lịch hẹn';
      case ReminderFilter.health:
        return 'Nhật ký sức khỏe';
      case ReminderFilter.all:
        return 'Nhắc nhở';
    }
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
          style: GoogleFonts.plusJakartaSans(
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
            ? const Center(
                key: ValueKey<String>('loading'),
                child: CircularProgressIndicator(
                  color: StyleTokens.buttonPrimary,
                ),
              )
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
        actionLabel: 'Thử lại',
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
          primaryLabel: 'Thuốc',
          secondaryLabel: 'Lịch hẹn',
        ),
        const SizedBox(height: 18),
        if (meds.isNotEmpty) ...<Widget>[
          _sectionHeader('Lịch uống thuốc', 'assets/icons/nav/ic_heart.svg'),
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
          _sectionHeader('Lịch hẹn', 'assets/icons/nav/ic_calendar.svg'),
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
            style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, {required bool isMed}) {
    final String title = _itemTitle(item);
    final String subtitle = isMed ? _medSubtitle(item) : _apptSubtitle(item);
    final bool highlighted =
        item['id'] == widget.highlightedReminderId ||
        item['local_id'] == widget.highlightedReminderId;
    return Semantics(
      button: true,
      label: '$title. $subtitle. Chạm để xem chi tiết.',
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
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
          primaryLabel: 'Bản ghi',
          secondaryLabel: 'Chờ xử lý',
        ),
        const SizedBox(height: 18),
        _sectionHeader('Nhật ký sức khỏe', 'assets/icons/nav/ic_activity.svg'),
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
        : _metricTypeVi(log['metric_type'] as String? ?? '');
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                  if (detail.isNotEmpty) const SizedBox(height: 3),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      style: GoogleFonts.plusJakartaSans(
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
                isSymptom ? 'Triệu chứng' : 'Chỉ số',
                style: GoogleFonts.plusJakartaSans(
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
      message: 'Chưa có nhắc nhở nào.\nThêm bằng giọng nói hoặc cài đặt.',
    );
  }

  Widget _buildHealthPlaceholder() {
    return _buildStateMessage(
      key: const ValueKey<String>('empty-health'),
      iconAsset: 'assets/icons/nav/ic_activity.svg',
      message: 'Nhật ký sức khỏe sẽ hiển thị\nkhi có dữ liệu ghi nhận.',
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
            style: GoogleFonts.plusJakartaSans(
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

  // ── Helpers ──

  static String _metricTypeVi(String type) {
    switch (type) {
      case 'blood_pressure':
        return 'Huyết áp';
      case 'heart_rate':
        return 'Nhịp tim';
      case 'temperature':
        return 'Nhiệt độ';
      case 'blood_sugar':
        return 'Đường huyết';
      case 'weight':
        return 'Cân nặng';
      case 'height':
        return 'Chiều cao';
      case 'spo2':
        return 'SpO2';
      default:
        return type;
    }
  }

  static String _frequencyVi(String? freq) {
    switch (freq?.toLowerCase()) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'twice_daily':
        return '2 lần/ngày';
      default:
        return freq ?? '';
    }
  }

  String _itemTitle(Map<String, dynamic> item) {
    return item['name'] as String? ?? item['title'] as String? ?? '';
  }

  String _medSubtitle(Map<String, dynamic> item) {
    final List<String> times =
        (item['times'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final String dosage = item['dosage'] as String? ?? '';
    final String freq = _frequencyVi(item['frequency'] as String?);
    final bool taken = item['taken'] == true;
    final bool skipped = item['skipped'] == true;

    final List<String> parts = <String>[];
    if (dosage.isNotEmpty) parts.add(dosage);
    if (times.isNotEmpty) parts.add(times.join(', '));
    if (freq.isNotEmpty) parts.add(freq);
    if (taken) {
      parts.add('✓ Đã uống');
    } else if (skipped) {
      parts.add('✗ Bỏ qua');
    }
    return parts.join(' · ');
  }

  String _apptSubtitle(Map<String, dynamic> item) {
    final String? dt = item['datetime'] as String?;
    final String? location = item['location'] as String?;
    final List<String> parts = <String>[];

    if (dt != null && dt.isNotEmpty) {
      try {
        final DateTime parsed = DateTime.parse(dt).toLocal();
        parts.add(
          '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}'
          ' lúc ${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}',
        );
      } catch (_) {
        parts.add(dt);
      }
    }
    if (location != null && location.isNotEmpty) {
      parts.add(location);
    }
    return parts.join(' · ');
  }

  // ── Detail bottom sheet ──

  void _showItemDetail(Map<String, dynamic> item, {required bool isMed}) {
    final String title = _itemTitle(item);
    final String subtitle = isMed ? _medSubtitle(item) : _apptSubtitle(item);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: StyleTokens.surfaceCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: StyleTokens.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: SvgPicture.asset(
                              isMed
                                  ? 'assets/icons/nav/ic_heart.svg'
                                  : 'assets/icons/nav/ic_calendar.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                StyleTokens.buttonPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: StyleTokens.textPrimary,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 5),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: StyleTokens.textMuted,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isMed) ...<Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _sheetAction(
                              ctx,
                              label: 'Đã uống',
                              color: StyleTokens.buttonPrimary,
                              textColor: StyleTokens.buttonOnPrimary,
                              onTap: () {
                                Navigator.pop(ctx);
                                _markMedication(item, taken: true);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _sheetAction(
                              ctx,
                              label: 'Bỏ qua',
                              color: StyleTokens.background,
                              textColor: StyleTokens.textSecondary,
                              onTap: () {
                                Navigator.pop(ctx);
                                _markMedication(item, taken: false);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    _sheetAction(
                      ctx,
                      label: 'Xoá nhắc nhở',
                      color: const Color(0xFFFFEBEB),
                      textColor: StyleTokens.error,
                      onTap: () {
                        Navigator.pop(ctx);
                        _deleteReminder(item);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sheetAction(
    BuildContext ctx, {
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markMedication(
    Map<String, dynamic> item, {
    required bool taken,
  }) async {
    HapticFeedback.lightImpact();
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null) return;
    final AiseeHealthService svc = AiseeHealthService();
    try {
      final Map<String, dynamic> data = {
        'reminder_id': item['id'],
        'medication_name': _itemTitle(item),
      };
      if (taken) {
        await svc.markMedicationTaken(tokens.accessToken, data);
        unawaited(
          AiseeAnalyticsService.instance.track(
            AiseeAnalyticsEvent.medicationTaken,
            parameters: <String, Object?>{'source': 'reminders'},
          ),
        );
      } else {
        await svc.markMedicationSkipped(tokens.accessToken, data);
        unawaited(
          AiseeAnalyticsService.instance.track(
            AiseeAnalyticsEvent.medicationSkipped,
            parameters: <String, Object?>{'source': 'reminders'},
          ),
        );
      }
    } catch (_) {}
    svc.close();
  }
}
