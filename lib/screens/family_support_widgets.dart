import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/aisee_supporter_models.dart';
import '../theme/style_tokens.dart';

const int _dailyAdLimit = 50;
const Color _medicalInk = StyleTokens.textPrimary;
const Color _medicalBlue = StyleTokens.buttonPrimary;
const Color _medicalMint = Color(0xFF4CB8A8);
const Color _medicalMintSoft = Color(0xFFEAF7F3);
const Color _medicalAmber = Color(0xFF7C6FE8);
const Color _medicalFreshSky = Color(0xFF4F80F0);
const Color _coinGold = Color(0xFFD69A1E);
const Color _coinGoldSoft = Color(0xFFFFF4D8);
const Color _medicalSurface = StyleTokens.surfaceCard;
const Color _medicalBorder = Color(0xFFE7ECF4);
const Color _medicalBanner = Color(0xFFEAF3FF);
const double _communityAvatarSize = 34;
const double _communityAvatarOverlap = 21;

String _dicebearAvatarUrl(String seed) {
  return 'https://api.dicebear.com/9.x/notionists/png?seed=${Uri.encodeComponent(seed)}&size=96&backgroundColor=e8e8e8';
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = _medicalSurface,
    this.borderColor = _medicalBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class SupporterWelcomeBanner extends StatelessWidget {
  const SupporterWelcomeBanner({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 186,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _medicalBanner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEAFF)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFFF2F7FF),
                      const Color(0xFFD8E9FF).withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 48,
              bottom: 18,
              child: Opacity(
                opacity: 0.92,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/support_banner.svg',
                    width: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 178),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          PhosphorIcons.usersThree(PhosphorIconsStyle.regular),
                          size: 14,
                          color: _medicalMint,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _tagLabel(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aiseeTextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _medicalBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    width: 220,
                    child: Text(
                      title,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.14,
                        color: _medicalInk,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 210,
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        color: StyleTokens.textSecondary,
                      ),
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

  String _tagLabel(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Cùng nhau tạo tác động' : 'Creating impact together';
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 22,
    this.child,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? _medicalBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          child ?? Icon(icon, size: iconSize, color: iconColor ?? _medicalBlue),
    );
  }
}

class SupporterHeroCard extends StatelessWidget {
  const SupporterHeroCard({
    super.key,
    required this.title,
    required this.rateHint,
    required this.coinBalance,
    required this.coinLabel,
    required this.adsWatchedToday,
    required this.adsLabel,
  });

  final String title;
  final String rateHint;
  final int coinBalance;
  final String coinLabel;
  final int adsWatchedToday;
  final String adsLabel;

  @override
  Widget build(BuildContext context) {
    final double progress = (adsWatchedToday / _dailyAdLimit).clamp(0.0, 1.0);

    return _SupportCard(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      backgroundColor: _medicalSurface,
      borderColor: _medicalBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _IconBadge(
                icon: PhosphorIcons.wallet(PhosphorIconsStyle.regular),
                backgroundColor: _medicalBlue.withValues(alpha: 0.10),
                iconColor: _medicalBlue,
                size: 46,
                iconSize: 21,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aiseeTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    color: _medicalBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$coinBalance',
                    style: aiseeTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      letterSpacing: 0,
                      color: _medicalBlue,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _coinGoldSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIcons.coins(PhosphorIconsStyle.duotone),
                      size: 15,
                      color: _coinGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ProgressBlock(
            progress: progress,
            label: adsLabel,
            value: '$adsWatchedToday/$_dailyAdLimit',
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.progress,
    required this.label,
    required this.value,
  });

  final double progress;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aiseeTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ),
            Text(
              value,
              style: aiseeTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: StyleTokens.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: _medicalBlue.withValues(alpha: 0.14),
            valueColor: const AlwaysStoppedAnimation<Color>(_medicalBlue),
          ),
        ),
      ],
    );
  }
}

class SupporterActionPanel extends StatelessWidget {
  const SupporterActionPanel({
    super.key,
    required this.watchAdLabel,
    required this.redeemLabel,
    required this.familyLinkLabel,
    required this.busy,
    required this.canRedeem,
    required this.onWatchAd,
    required this.onRedeem,
    required this.onOpenFamily,
  });

  final String watchAdLabel;
  final String redeemLabel;
  final String familyLinkLabel;
  final bool busy;
  final bool canRedeem;
  final VoidCallback onWatchAd;
  final VoidCallback onRedeem;
  final VoidCallback onOpenFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _FullWidthActionButton(
          icon: PhosphorIcons.playCircle(PhosphorIconsStyle.regular),
          label: _watchTitle(context),
          subtitle: _watchSubtitle(context),
          enabled: !busy,
          onTap: onWatchAd,
          accent: _medicalBlue,
          busy: busy,
          filled: true,
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _PanelActionButton(
                  icon: PhosphorIcons.gift(PhosphorIconsStyle.duotone),
                  label: _redeemTitle(context),
                  subtitle: _redeemSubtitle(context),
                  enabled: !busy && canRedeem,
                  onTap: onRedeem,
                  accent: _medicalMint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PanelActionButton(
                  icon: PhosphorIcons.usersThree(PhosphorIconsStyle.duotone),
                  label: _familyTitle(context),
                  subtitle: _familySubtitle(context),
                  enabled: true,
                  onTap: onOpenFamily,
                  accent: _medicalAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _watchTitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Xem quảng cáo' : 'Watch ads';
  }

  String _watchSubtitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Nhận xu và lượt hỗ trợ' : 'Earn coins and support credits';
  }

  String _redeemTitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Quy đổi lượt hỗ trợ' : 'Redeem support credits';
  }

  String _redeemSubtitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Dùng xu để đổi lượt' : 'Use coins for credits';
  }

  String _familyTitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Quản lý người thân' : 'Manage family';
  }

  String _familySubtitle(BuildContext context) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi ? 'Danh sách hỗ trợ' : 'Support list';
  }
}

class _FullWidthActionButton extends StatelessWidget {
  const _FullWidthActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    required this.accent,
    this.busy = false,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;
  final bool busy;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color surface = filled ? accent : _medicalSurface;
    final Color contentColor = enabled
        ? (filled ? Colors.white : _medicalInk)
        : StyleTokens.textMuted;
    final Color subtitleColor = enabled
        ? (filled ? Colors.white.withValues(alpha: 0.82) : StyleTokens.textSecondary)
        : StyleTokens.textMuted;
    final Color badgeBg = filled
        ? Colors.white.withValues(alpha: 0.20)
        : accent.withValues(alpha: 0.12);
    final Color badgeIcon = enabled ? (filled ? Colors.white : accent) : StyleTokens.textMuted;
    final Color caretColor = enabled ? (filled ? Colors.white : accent) : StyleTokens.textMuted;
    final Color borderColor = filled ? accent : _medicalBorder;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: <Widget>[
              _IconBadge(
                icon: icon,
                backgroundColor: badgeBg,
                iconColor: badgeIcon,
                size: 36,
                iconSize: 18,
                child: busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: filled ? Colors.white : accent,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        color: contentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: aiseeTextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: caretColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color contentColor = enabled ? _medicalInk : StyleTokens.textMuted;

    return Material(
      color: _medicalSurface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _medicalBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _IconBadge(
                icon: icon,
                backgroundColor: accent.withValues(alpha: 0.12),
                iconColor: enabled ? accent : StyleTokens.textMuted,
                size: 32,
                iconSize: 17,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: aiseeTextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: aiseeTextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ],
          ),
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
    required this.title,
    required this.peopleCount,
    required this.aiTurns,
    required this.adsWatched,
    required this.labelPeople,
    required this.labelAITurns,
    required this.labelAds,
  });

  final String title;
  final int peopleCount;
  final int aiTurns;
  final int adsWatched;
  final String labelPeople;
  final String labelAITurns;
  final String labelAds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: aiseeTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _medicalInk,
          ),
        ),
        const SizedBox(height: 10),
        _SupportCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: _medicalSurface,
          borderColor: _medicalBorder,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _InlineStat(
                  icon: PhosphorIcons.user(PhosphorIconsStyle.duotone),
                  value: _fmtInt(peopleCount),
                  label: labelPeople,
                  accent: _medicalFreshSky,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _InlineStat(
                  icon: PhosphorIcons.robot(PhosphorIconsStyle.duotone),
                  value: _fmtInt(aiTurns),
                  label: labelAITurns,
                  accent: _medicalMint,
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _InlineStat(
                  icon: PhosphorIcons.heart(PhosphorIconsStyle.duotone),
                  value: _fmtInt(adsWatched),
                  label: labelAds,
                  accent: _medicalAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _medicalBorder,
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _IconBadge(
          icon: icon,
          backgroundColor: accent.withValues(alpha: 0.10),
          iconColor: accent,
          size: 32,
          iconSize: 17,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: aiseeTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1,
            color: _medicalInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: aiseeTextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: _medicalInk.withValues(alpha: 0.58),
          ),
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
    required this.supporters,
    required this.title,
    required this.labelPeople,
    required this.labelAITurns,
    required this.labelSupporters,
    this.onTap,
  });

  final int totalCaredUsers;
  final int totalAITurns;
  final int activeSupporters;
  final List<CommunitySupporterProfile> supporters;
  final String title;
  final String labelPeople;
  final String labelAITurns;
  final String labelSupporters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              title,
              style: aiseeTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _medicalInk,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: _SupportCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              backgroundColor: _medicalSurface,
              borderColor: _medicalBorder,
              child: Row(
                children: <Widget>[
                  _CommunityAvatarStack(
                    supporters: supporters,
                    activeSupporters: activeSupporters,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _communityLead(context, activeSupporters),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: aiseeTextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _medicalInk,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _communitySub(context, totalCaredUsers, totalAITurns),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: aiseeTextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                            color: StyleTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _medicalBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                      size: 17,
                      color: _medicalBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _communityLead(BuildContext context, int activeSupporters) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    final int others = activeSupporters < 0 ? 0 : activeSupporters;
    return vi ? 'Bạn và $others người khác' : 'You and $others others';
  }

  String _communitySub(
    BuildContext context,
    int totalCaredUsers,
    int totalAITurns,
  ) {
    final bool vi = Localizations.localeOf(context).languageCode == 'vi';
    return vi
        ? '${_fmtInt(totalCaredUsers)} người đang nhận ${_fmtInt(totalAITurns)} lượt hỗ trợ.'
        : '${_fmtInt(totalCaredUsers)} people are receiving ${_fmtInt(totalAITurns)} support credits.';
  }
}

class _CommunityAvatarStack extends StatelessWidget {
  const _CommunityAvatarStack({
    required this.supporters,
    required this.activeSupporters,
  });

  final List<CommunitySupporterProfile> supporters;
  final int activeSupporters;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      _medicalFreshSky,
      _medicalMint,
      _medicalBlue,
      _medicalAmber,
    ];
    final int visibleCount = supporters.length.clamp(0, 4);
    final int extraCount = activeSupporters > visibleCount
        ? activeSupporters - visibleCount
        : 0;
    final bool showExtra = extraCount > 0 || visibleCount == 0;
    final int circleCount = visibleCount + (showExtra ? 1 : 0);
    final double width = circleCount <= 1
        ? _communityAvatarSize
        : _communityAvatarSize + ((circleCount - 1) * _communityAvatarOverlap);

    return SizedBox(
      width: width,
      height: _communityAvatarSize,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * _communityAvatarOverlap,
              child: _CommunityAvatar(
                key: ValueKey<String>(supporters[i].anonSeed),
                supporter: supporters[i],
                accent: colors[i % colors.length],
              ),
            ),
          if (showExtra)
            Positioned(
              left: visibleCount * _communityAvatarOverlap,
              child: Container(
                width: _communityAvatarSize,
                height: _communityAvatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _medicalBlue.withValues(alpha: 0.10),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Text(
                  extraCount > 0 ? '+$extraCount' : '+',
                  style: aiseeTextStyle(
                    fontSize: extraCount > 9 ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    color: _medicalBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityAvatar extends StatefulWidget {
  const _CommunityAvatar({
    super.key,
    required this.supporter,
    required this.accent,
  });

  final CommunitySupporterProfile supporter;
  final Color accent;

  @override
  State<_CommunityAvatar> createState() => _CommunityAvatarState();
}

class _CommunityAvatarState extends State<_CommunityAvatar> {
  int _urlIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> urls = _avatarUrls();
    final String url = urls[_urlIndex.clamp(0, urls.length - 1)];
    return Container(
      width: _communityAvatarSize,
      height: _communityAvatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.accent.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        width: _communityAvatarSize,
        height: _communityAvatarSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (_urlIndex < urls.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _urlIndex += 1);
              }
            });
          }
          return ColoredBox(color: widget.accent.withValues(alpha: 0.12));
        },
      ),
    );
  }

  List<String> _avatarUrls() {
    return <String>[_dicebearAvatarUrl(widget.supporter.anonSeed)];
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
    final double nextTurnProgress = ((coinBalance % 100) / 100).clamp(0.0, 1.0);

    return _SupportCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      backgroundColor: _medicalSurface,
      borderColor: _medicalBorder,
      child: Row(
        children: <Widget>[
          _IconBadge(
            icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
            backgroundColor: _medicalBlue.withValues(alpha: 0.10),
            iconColor: _medicalBlue,
            size: 34,
            iconSize: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aiseeTextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _medicalInk,
                        ),
                      ),
                    ),
                    Text(
                      '$coinBalance $coinLabel',
                      style: aiseeTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: _medicalInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: coinBalance == 0 ? 0 : nextTurnProgress,
                    backgroundColor: _medicalMintSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(_medicalBlue),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        rateHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: aiseeTextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _medicalInk.withValues(alpha: 0.50),
                        ),
                      ),
                    ),
                    if (onRedeem != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: busy ? null : onRedeem,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _medicalBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  redeemLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: aiseeTextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _medicalBlue,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
