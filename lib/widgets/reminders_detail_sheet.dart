import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/services/aisee_reminders_data_provider.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:aiseeapp/theme/style_tokens.dart';

class RemindersDetailSheet extends StatelessWidget {
  const RemindersDetailSheet({
    super.key,
    required this.item,
    required this.isMed,
    required this.onTaken,
    required this.onSkipped,
    required this.onDelete,
    required this.onClose,
  });

  final Map<String, dynamic> item;
  final bool isMed;
  final VoidCallback onTaken;
  final VoidCallback onSkipped;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> item,
    required bool isMed,
    required VoidCallback onTaken,
    required VoidCallback onSkipped,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return RemindersDetailSheet(
          item: item,
          isMed: isMed,
          onTaken: () {
            Navigator.pop(ctx);
            onTaken();
          },
          onSkipped: () {
            Navigator.pop(ctx);
            onSkipped();
          },
          onDelete: () {
            Navigator.pop(ctx);
            onDelete();
          },
          onClose: () => Navigator.pop(ctx),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String title = AiseeRemindersDataProvider.itemTitle(item);
    final String subtitle = isMed
        ? AiseeRemindersDataProvider.medSubtitle(item, l10n)
        : AiseeRemindersDataProvider.apptSubtitle(item, l10n);

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
                            style: aiseeTextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: StyleTokens.textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: aiseeTextStyle(
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
                          label: l10n.remindersTakenStatus,
                          color: StyleTokens.buttonPrimary,
                          textColor: StyleTokens.buttonOnPrimary,
                          onTap: onTaken,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sheetAction(
                          label: l10n.remindersSkippedStatus,
                          color: StyleTokens.background,
                          textColor: StyleTokens.textSecondary,
                          onTap: onSkipped,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                _sheetAction(
                  label: l10n.remindersDeletePrompt,
                  color: const Color(0xFFFFEBEB),
                  textColor: StyleTokens.error,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetAction({
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
                style: aiseeTextStyle(
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
}
