import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_dashboard_models.dart';
import '../theme/style_tokens.dart';
import 'family_dashboard_format.dart';

class FamilyDashboardHealthTab extends StatelessWidget {
  const FamilyDashboardHealthTab({
    required this.loading,
    required this.health,
    required this.onRefresh,
    super.key,
  });

  final bool loading;
  final DashboardHealth? health;
  final Future<void> Function() onRefresh;

  static const String _icCalendar = 'assets/icons/nav/ic_calendar.svg';
  static const String _icActivity = 'assets/icons/nav/ic_activity.svg';
  static const String _icHeart = 'assets/icons/nav/ic_heart.svg';

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ColoredBox(
        color: StyleTokens.background,
        child: Center(child: CircularProgressIndicator()),
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
                  'Không có dữ liệu',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kéo xuống để tải lại.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
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
              'Theo dõi sức khỏe',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: StyleTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thuốc trong ngày, triệu chứng và chỉ số gần nhất.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                color: StyleTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _HealthSectionHeader(title: 'Thuốc hôm nay', iconAsset: _icCalendar),
            const SizedBox(height: 10),
            if (h.medications.isEmpty)
              _HealthEmptyCard(
                message: 'Chưa có thuốc nào',
                iconAsset: _icCalendar,
              )
            else
              ...h.medications.map(_MedAdherenceCard.new),
            const SizedBox(height: 22),
            _HealthSectionHeader(title: 'Triệu chứng gần đây', iconAsset: _icActivity),
            const SizedBox(height: 10),
            if (h.recentSymptoms.isEmpty)
              _HealthEmptyCard(
                message: 'Không có triệu chứng',
                iconAsset: _icActivity,
              )
            else
              ...h.recentSymptoms.map(_SymptomCard.new),
            const SizedBox(height: 22),
            _HealthSectionHeader(title: 'Chỉ số sức khỏe', iconAsset: _icHeart),
            const SizedBox(height: 10),
            if (h.recentMetrics.isEmpty)
              _HealthEmptyCard(
                message: 'Không có chỉ số',
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
  const _HealthSectionHeader({
    required this.title,
    required this.iconAsset,
  });

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
                style: GoogleFonts.plusJakartaSans(
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
  const _HealthEmptyCard({
    required this.message,
    required this.iconAsset,
  });

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
            style: GoogleFonts.plusJakartaSans(
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

class _MedAdherenceCard extends StatelessWidget {
  const _MedAdherenceCard(this.m);

  static const String _icCalendar = 'assets/icons/nav/ic_calendar.svg';

  final MedWithAdherence m;

  @override
  Widget build(BuildContext context) {
    final taken = m.takenToday;
    final statusBg = taken
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final statusFg = taken
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final iconBg = taken
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFF3E0);
    final iconFg = taken
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);

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
                        style: GoogleFonts.plusJakartaSans(
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
                        taken ? 'Đã uống' : 'Chưa uống',
                        style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    Text(
                      formatFamilyDashboardTime(s.loggedAt),
                      style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.value}${m.unit != null && m.unit!.trim().isNotEmpty ? ' ${m.unit}' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: StyleTokens.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatFamilyDashboardTime(m.loggedAt),
                  style: GoogleFonts.plusJakartaSans(
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
