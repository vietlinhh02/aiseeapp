import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/aisee_reminder.dart';
import '../services/aisee_reminder_service.dart';
import '../theme/style_tokens.dart';

class UserPersonalTab extends StatefulWidget {
  const UserPersonalTab({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  /// Gọi từ parent để refresh danh sách nhắc nhở (VD khi chuyển tab).
  static final GlobalKey<UserPersonalTabState> tabKey =
      GlobalKey<UserPersonalTabState>();

  @override
  State<UserPersonalTab> createState() => UserPersonalTabState();
}

class UserPersonalTabState extends State<UserPersonalTab> {
  List<AiseeReminder> _reminders = <AiseeReminder>[];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  /// Reload reminders — gọi được từ bên ngoài qua [UserPersonalTab.tabKey].
  void refreshReminders() => _loadReminders();

  Future<void> _loadReminders() async {
    final List<AiseeReminder> loaded =
        await AiseeReminderService.instance.loadAll();
    if (!mounted) return;
    setState(() => _reminders = loaded);
  }

  Future<void> _deleteReminder(int id) async {
    await AiseeReminderService.instance.cancelReminder(id);
    await _loadReminders();
  }

  List<AiseeReminder> get _medications => _reminders
      .where((AiseeReminder r) => r.type == AiseeReminderType.medication)
      .toList();

  List<AiseeReminder> get _appointments => _reminders
      .where((AiseeReminder r) => r.type == AiseeReminderType.appointment)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Cá nhân. Lịch uống thuốc và tin nhắn của bạn.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Text(
            'Cá nhân',
            style: StyleTokens.titleScreen().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Thông tin cá nhân và lịch nhắc nhở của bạn.',
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _buildMedicationSection(),
          const SizedBox(height: 16),
          _buildAppointmentSection(),
          const SizedBox(height: 16),
          _InfoSection(
            iconAsset: 'assets/icons/nav/ic_voice.svg',
            title: 'Tin nhắn thoại chưa đọc',
            body: 'Không có tin mới từ người thân.',
          ),
          const SizedBox(height: 16),
          _InfoSection(
            iconAsset: 'assets/icons/nav/ic_activity.svg',
            title: 'Nhật ký sức khỏe gần đây',
            body: 'Tóm tắt sẽ hiển thị khi có dữ liệu.',
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildMedicationSection() {
    final List<AiseeReminder> meds = _medications;
    if (meds.isEmpty) {
      return _InfoSection(
        iconAsset: 'assets/icons/nav/ic_heart.svg',
        title: 'Lịch uống thuốc hôm nay',
        body: 'Chưa có lịch — thêm từ cài đặt hoặc giọng nói.',
      );
    }
    return _ReminderSection(
      title: 'Lich uong thuoc hom nay',
      items: meds,
      iconAsset: 'assets/icons/nav/ic_heart.svg',
      subtitleBuilder: _medicationSubtitle,
      onDelete: _deleteReminder,
    );
  }

  Widget _buildAppointmentSection() {
    final List<AiseeReminder> appts = _appointments;
    if (appts.isEmpty) {
      return _InfoSection(
        iconAsset: 'assets/icons/nav/ic_calendar.svg',
        title: 'Lịch hẹn',
        body: 'Chưa có lịch hẹn nào.',
      );
    }
    return _ReminderSection(
      title: 'Lich hen',
      items: appts,
      iconAsset: 'assets/icons/nav/ic_calendar.svg',
      subtitleBuilder: _appointmentSubtitle,
      onDelete: _deleteReminder,
    );
  }

  String _medicationSubtitle(AiseeReminder r) {
    final List<String> times = r.times ?? <String>[];
    if (times.isEmpty) return r.frequency ?? '';
    final String joined = times.join(', ');
    if (r.frequency != null) return '$joined (${r.frequency})';
    return joined;
  }

  String _appointmentSubtitle(AiseeReminder r) {
    return r.datetime ?? '';
  }

  Widget _buildSignOutButton() {
    return Semantics(
      button: true,
      label: 'Đăng xuất khỏi AiSee',
      child: Material(
        color: StyleTokens.buttonPrimary,
        borderRadius: BorderRadius.circular(31),
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSignOut();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Đăng xuất',
                style: StyleTokens.socialLabel().copyWith(
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.title,
    required this.items,
    required this.iconAsset,
    required this.subtitleBuilder,
    required this.onDelete,
  });

  final String title;
  final List<AiseeReminder> items;
  final String iconAsset;
  final String Function(AiseeReminder) subtitleBuilder;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: StyleTokens.titleScreen().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 8),
              _ReminderRow(
                iconAsset: iconAsset,
                reminder: items[i],
                subtitle: subtitleBuilder(items[i]),
                onDelete: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.iconAsset,
    required this.reminder,
    required this.subtitle,
    required this.onDelete,
  });

  final String iconAsset;
  final AiseeReminder reminder;
  final String subtitle;
  final Future<void> Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 18,
          height: 18,
          child: SvgPicture.asset(
            iconAsset,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              StyleTokens.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                reminder.title,
                style: StyleTokens.titleScreen().copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/nav/ic_delete.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFF6B6B),
              BlendMode.srcIn,
            ),
          ),
          tooltip: 'Xoá nhắc nhở',
          onPressed: () => onDelete(reminder.id),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.iconAsset,
    required this.title,
    required this.body,
  });

  final String iconAsset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StyleTokens.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                iconAsset,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: StyleTokens.titleScreen().copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: StyleTokens.bodySmall().copyWith(
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
