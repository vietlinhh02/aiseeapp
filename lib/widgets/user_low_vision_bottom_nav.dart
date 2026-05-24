import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';

/// Thanh điều hướng nổi — nền đen, pill shape, active trắng + label.
class UserLowVisionBottomNav extends StatelessWidget {
  const UserLowVisionBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
    this.showLabel = true,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<NavItemData> items;
  final bool showLabel;

  static List<NavItemData> defaultItems(AppLocalizations l) => [
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_wave.svg',
      label: l.navAssistant,
      semanticsLabel: l.navAssistantLabel,
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_message.svg',
      label: l.navContacts,
      semanticsLabel: l.navContactsLabel,
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_profile.svg',
      label: l.navPersonal,
      semanticsLabel: l.navPersonalLabel,
    ),
  ];

  static List<NavItemData> familyItems(AppLocalizations l) => [
    NavItemData(
      iconData: Icons.volunteer_activism_rounded,
      label: l.navSupport,
      semanticsLabel: l.navSupportLabel,
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_message.svg',
      label: l.navMessages,
      semanticsLabel: l.navMessagesLabel,
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_profile.svg',
      label: l.navPersonal,
      semanticsLabel: l.navPersonalFamilyLabel,
    ),
  ];

  void _onSelect(int index) {
    HapticFeedback.selectionClick();
    onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: StyleTokens.navBarBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == items.length - 1 ? 0 : 4,
                  ),
                  child: _NavPill(
                    selected: currentIndex == i,
                    iconAsset: items[i].iconAsset,
                    iconData: items[i].iconData,
                    label: items[i].label,
                    semanticsLabel: items[i].semanticsLabel,
                    showLabel: showLabel,
                    onTap: () => _onSelect(i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NavItemData {
  const NavItemData({
    this.iconAsset,
    this.iconData,
    required this.label,
    required this.semanticsLabel,
  }) : assert(iconAsset != null || iconData != null);

  final String? iconAsset;
  final IconData? iconData;
  final String label;
  final String semanticsLabel;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.selected,
    this.iconAsset,
    this.iconData,
    required this.label,
    required this.semanticsLabel,
    required this.showLabel,
    required this.onTap,
  });

  final bool selected;
  final String? iconAsset;
  final IconData? iconData;
  final String label;
  final String semanticsLabel;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color pillColor = selected
        ? StyleTokens.navSelectedPill
        : StyleTokens.navInactivePill;
    final Color contentColor = selected
        ? StyleTokens.navSelectedOnPill
        : StyleTokens.navUnselectedIcon;
    final AppLocalizations l = AppLocalizations.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      hint: l.navDoubleTapHint,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: pillColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconAsset != null)
                  SvgPicture.asset(
                    iconAsset!,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      contentColor,
                      BlendMode.srcIn,
                    ),
                  )
                else if (iconData != null)
                  Icon(iconData, size: 20, color: contentColor),
                if (selected && showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: aiseeTextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.5,
                      color: StyleTokens.navSelectedOnPill,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
