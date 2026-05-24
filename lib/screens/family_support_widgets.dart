import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StyleTokens.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: StyleTokens.textSecondary),
            const SizedBox(height: 8),
            Text(
              value,
              style: aiseeTextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: StyleTokens.textPrimary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: aiseeTextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: StyleTokens.textMuted,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtInt(int n) {
  if (n >= 1000) {
    final String d = (n / 1000).toStringAsFixed(3);
    final int dot = d.indexOf('.');
    final String intPart = d.substring(0, dot);
    final String decPart = d.substring(dot + 1);
    final String trimmed = decPart.replaceAll(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? intPart : '$intPart.$trimmed';
  }
  return n.toString();
}

class SupporterPersonalStatsRow extends StatelessWidget {
  const SupporterPersonalStatsRow({
    super.key,
    required this.peopleCount,
    required this.aiTurns,
    required this.adsWatched,
    required this.labelPeople,
    required this.labelAITurns,
    required this.labelAds,
  });

  final int peopleCount;
  final int aiTurns;
  final int adsWatched;
  final String labelPeople;
  final String labelAITurns;
  final String labelAds;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _StatCard(
          icon: Icons.people_rounded,
          value: _fmtInt(peopleCount),
          label: labelPeople,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.auto_awesome_rounded,
          value: _fmtInt(aiTurns),
          label: labelAITurns,
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.smart_display_rounded,
          value: _fmtInt(adsWatched),
          label: labelAds,
        ),
      ],
    );
  }
}

class SupporterCommunityStatsRow extends StatelessWidget {
  const SupporterCommunityStatsRow({
    super.key,
    required this.totalCaredUsers,
    required this.totalAITurns,
    required this.activeSupporters,
    required this.title,
    required this.labelPeople,
    required this.labelAITurns,
    required this.labelSupporters,
  });

  final int totalCaredUsers;
  final int totalAITurns;
  final int activeSupporters;
  final String title;
  final String labelPeople;
  final String labelAITurns;
  final String labelSupporters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: aiseeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            _StatCard(
              icon: Icons.groups_rounded,
              value: _fmtInt(totalCaredUsers),
              label: labelPeople,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.auto_awesome_rounded,
              value: _fmtInt(totalAITurns),
              label: labelAITurns,
            ),
            const SizedBox(width: 8),
            _StatCard(
              icon: Icons.favorite_rounded,
              value: _fmtInt(activeSupporters),
              label: labelSupporters,
            ),
          ],
        ),
      ],
    );
  }
}

class SupporterBalancePoolCard extends StatelessWidget {
  const SupporterBalancePoolCard({
    super.key,
    required this.coinBalance,
    required this.title,
    required this.conversionLabel,
    required this.redeemLabel,
    required this.rateHint,
    required this.coinLabel,
    this.busy = false,
    this.onRedeem,
  });

  final int coinBalance;
  final String title;
  final String conversionLabel;
  final String redeemLabel;
  final String rateHint;
  final String coinLabel;
  final bool busy;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            title,
            style: aiseeTextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: StyleTokens.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StyleTokens.cardBorder),
          ),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 18,
                    color: StyleTokens.buttonPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coinBalance $coinLabel',
                    style: aiseeTextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                conversionLabel,
                style: aiseeTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textSecondary,
                ),
              ),
              if (onRedeem != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: busy ? null : onRedeem,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: StyleTokens.buttonPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            redeemLabel,
                            style: aiseeTextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: StyleTokens.buttonPrimary,
                            ),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                rateHint,
                style: aiseeTextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: StyleTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SupporterInfoCard extends StatelessWidget {
  const SupporterInfoCard({
    super.key,
    required this.title,
    required this.steps,
    required this.dailyLimit,
    required this.learnMoreLabel,
  });

  final String title;
  final List<String> steps;
  final String dailyLimit;
  final String learnMoreLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: StyleTokens.buttonPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: aiseeTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    String.fromCharCode(0x2460 + i),
                    style: aiseeTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: StyleTokens.buttonPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: aiseeTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: StyleTokens.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: StyleTokens.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dailyLimit,
              style: aiseeTextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: StyleTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: Text(title),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        for (final String s in steps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '\u2022 $s',
                              style: aiseeTextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(AppLocalizations.of(context).actionCancel),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              learnMoreLabel,
              style: aiseeTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: StyleTokens.buttonPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
