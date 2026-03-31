import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/aisee_dashboard_models.dart';
import '../theme/style_tokens.dart';

class FamilyDashboardMedsTab extends StatelessWidget {
  const FamilyDashboardMedsTab({
    required this.loading,
    required this.meds,
    required this.onRefresh,
    required this.onMedAction,
    super.key,
  });

  final bool loading;
  final List<MedStatus> meds;
  final Future<void> Function() onRefresh;
  final void Function(String action, DashboardMedication med) onMedAction;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (meds.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 200),
            Center(
              child: Text(
                'Chưa có thuốc nào',
                style: StyleTokens.bodySmall(),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meds.length,
        itemBuilder: (context, index) {
          final m = meds[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _medStatusSvg(m),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.medication.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${m.medication.dosage} - '
                        '${m.medication.times.join(", ")}',
                        style: StyleTokens.bodySmall(),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => onMedAction(action, m.medication),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _medStatusSvg(MedStatus m) {
  final String asset;
  final Color color;
  if (m.taken) {
    asset = 'assets/icons/nav/ic_check.svg';
    color = const Color(0xFF2E7D32);
  } else if (m.skipped) {
    asset = 'assets/icons/nav/ic_close.svg';
    color = const Color(0xFFC62828);
  } else {
    asset = 'assets/icons/nav/ic_radio_not_selected.svg';
    color = StyleTokens.textMuted;
  }
  return SvgPicture.asset(
    asset,
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

