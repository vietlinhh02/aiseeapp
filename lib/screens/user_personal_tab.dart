import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_api_models.dart';
import '../services/aisee_health_service.dart';
import '../services/aisee_session_store.dart';
import '../theme/style_tokens.dart';
import 'reminders_screen.dart';
import 'user_sponsor_screen.dart';

class UserPersonalTab extends StatefulWidget {
  const UserPersonalTab({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  static final GlobalKey<UserPersonalTabState> tabKey =
      GlobalKey<UserPersonalTabState>();

  @override
  State<UserPersonalTab> createState() => UserPersonalTabState();
}

class UserPersonalTabState extends State<UserPersonalTab> {
  int _medCount = 0;
  int _apptCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void refreshReminders() => _loadCounts();

  Future<void> _loadCounts() async {
    final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
    if (tokens == null || !mounted) return;
    final AiseeHealthService svc = AiseeHealthService();
    try {
      final List<Map<String, dynamic>> meds = await svc.fetchMedications(
        tokens.accessToken,
      );
      final List<Map<String, dynamic>> appts = await svc.fetchAppointments(
        tokens.accessToken,
      );
      if (!mounted) return;
      setState(() {
        _medCount = meds.length;
        _apptCount = appts.length;
      });
    } catch (_) {}
    svc.close();
  }

  void _openScreen(ReminderFilter filter) {
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => RemindersScreen(initialFilter: filter),
          ),
        )
        .then((_) => _loadCounts());
  }

  void _openSponsors() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserSponsorScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Cá nhân. Lịch uống thuốc và nhắc nhở của bạn.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Text(
            'Thông tin cá nhân và lịch nhắc nhở của bạn.',
            style: StyleTokens.bodySmall().copyWith(fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_heart.svg',
            title: 'Lịch uống thuốc',
            subtitle: _medCount > 0 ? '$_medCount nhắc nhở' : 'Chưa có lịch',
            onTap: () => _openScreen(ReminderFilter.medication),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_calendar.svg',
            title: 'Lịch hẹn',
            subtitle: _apptCount > 0
                ? '$_apptCount lịch hẹn'
                : 'Chưa có lịch hẹn',
            onTap: () => _openScreen(ReminderFilter.appointment),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_activity.svg',
            title: 'Nhật ký sức khỏe',
            subtitle: 'Xem chi tiết',
            onTap: () => _openScreen(ReminderFilter.health),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: 'Nhà tài trợ',
            subtitle: 'Các đơn vị đang đồng hành cùng dự án',
            onTap: _openSponsors,
          ),
          const SizedBox(height: 32),
          _buildSignOutButton(),
        ],
      ),
    );
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
                style: StyleTokens.socialLabel().copyWith(fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. Chạm để mở.',
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: StyleTokens.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      iconAsset,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.buttonPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StyleTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/nav/ic_arrow_right.svg',
                  width: 8,
                  height: 8,
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
}
