import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/aisee_dashboard_models.dart';
import '../theme/style_tokens.dart';
import 'family_dashboard_format.dart';

class FamilyDashboardAuditTab extends StatelessWidget {
  const FamilyDashboardAuditTab({
    required this.loading,
    required this.logs,
    required this.onRefresh,
    required this.onLogTap,
    super.key,
  });

  final bool loading;
  final List<AuditLogEntry> logs;
  final Future<void> Function() onRefresh;
  final void Function(AuditLogEntry log) onLogTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ColoredBox(
        color: StyleTokens.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (logs.isEmpty) {
      final AppLocalizations l = AppLocalizations.of(context);
      return ColoredBox(
        color: StyleTokens.background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l.dashboardAuditEmpty,
              textAlign: TextAlign.center,
              style: aiseeTextStyle(
                fontSize: 14,
                color: StyleTokens.textSecondary,
              ),
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
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final AuditLogEntry log = logs[index];
            return GestureDetector(
              onTap: () => onLogTap(log),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    familyDashboardAuditIcon(log.toolName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            log.toolLabel,
                            style: aiseeTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: StyleTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log.activitySubtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: aiseeTextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: StyleTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatFamilyDashboardTime(log.createdAt),
                            style: StyleTokens.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      'assets/icons/nav/ic_arrow_right.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.textMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _auditSvg(String asset, Color color) {
  return SvgPicture.asset(
    asset,
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

Widget familyDashboardAuditIcon(String toolName) {
  final n = toolName.toLowerCase();
  if (n.contains('call')) {
    return _auditSvg('assets/icons/nav/ic_call.svg', const Color(0xFF2E7D32));
  }
  if (n.contains('message')) {
    return _auditSvg('assets/icons/nav/ic_chat.svg', const Color(0xFF1565C0));
  }
  if (n.contains('emergency') || n.contains('sos')) {
    return _auditSvg(
      'assets/icons/nav/ic_danger_triangle.svg',
      const Color(0xFFC62828),
    );
  }
  if (n.contains('medication') || n.contains('med')) {
    return _auditSvg('assets/icons/nav/ic_heart.svg', const Color(0xFF6A1B9A));
  }
  return _auditSvg(
    'assets/icons/nav/ic_time_circle.svg',
    StyleTokens.textMuted,
  );
}

void showFamilyDashboardLogDetail(BuildContext context, AuditLogEntry log) {
  final AppLocalizations l = AppLocalizations.of(context);
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: StyleTokens.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            log.toolLabel,
            style: aiseeTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            log.activitySubtitle,
            style: aiseeTextStyle(
              fontSize: 14,
              height: 1.4,
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.dashboardAuditTime(formatFamilyDashboardTime(log.createdAt)),
            style: aiseeTextStyle(
              fontSize: 14,
              color: StyleTokens.textSecondary,
            ),
          ),
          if (log.params.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l.dashboardAuditDetails(
                log.params.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', '),
              ),
              style: aiseeTextStyle(
                fontSize: 14,
                color: StyleTokens.textSecondary,
              ),
            ),
          ],
          if (log.result != null) ...[
            const SizedBox(height: 8),
            Text(
              l.dashboardAuditResult(log.result!),
              style: aiseeTextStyle(
                fontSize: 14,
                color: StyleTokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StyleTokens.buttonPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l.dashboardClose,
                style: aiseeTextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
