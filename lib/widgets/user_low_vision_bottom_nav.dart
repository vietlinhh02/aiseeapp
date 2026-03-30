import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/style_tokens.dart';

/// Thanh điều hướng nổi — nền đen, pill shape, active trắng + label.
class UserLowVisionBottomNav extends StatelessWidget {
  const UserLowVisionBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    List<NavItemData>? items,
  }) : _items = items ?? _defaultItems;

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<NavItemData> _items;

  static const List<NavItemData> _defaultItems = [
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_wave.svg',
      label: 'Trợ lý',
      semanticsLabel:
          'Mục 1 trên 3: Trợ lý. '
          'Trang chủ. Trợ lý AiSee đang sẵn sàng nghe.',
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_3user.svg',
      label: 'Liên lạc',
      semanticsLabel:
          'Mục 2 trên 3: Liên lạc. '
          'Nhắn tin và gọi điện người thân.',
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_profile.svg',
      label: 'Cá nhân',
      semanticsLabel:
          'Mục 3 trên 3: Cá nhân. '
          'Cá nhân. Lịch uống thuốc và tin nhắn của bạn.',
    ),
  ];

  static const List<NavItemData> familyItems = [
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_3user.svg',
      label: 'Gia đình',
      semanticsLabel: 'Mục 1 trên 3: Gia đình. Danh sách liên lạc gia đình.',
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_paper.svg',
      label: 'Tin nhắn',
      semanticsLabel: 'Mục 2 trên 3: Tin nhắn. Hộp thư đến.',
    ),
    NavItemData(
      iconAsset: 'assets/icons/nav/ic_profile.svg',
      label: 'Cá nhân',
      semanticsLabel: 'Mục 3 trên 3: Cá nhân. Hồ sơ và cài đặt.',
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
            for (int i = 0; i < _items.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : 4,
                    right: i == _items.length - 1 ? 0 : 4,
                  ),
                  child: _NavPill(
                    selected: currentIndex == i,
                    iconAsset: _items[i].iconAsset,
                    label: _items[i].label,
                    semanticsLabel: _items[i].semanticsLabel,
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
    required this.iconAsset,
    required this.label,
    required this.semanticsLabel,
  });

  final String iconAsset;
  final String label;
  final String semanticsLabel;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.selected,
    required this.iconAsset,
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final bool selected;
  final String iconAsset;
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color pillColor =
        selected ? StyleTokens.navSelectedPill : StyleTokens.navInactivePill;
    final Color contentColor =
        selected ? StyleTokens.navSelectedOnPill : StyleTokens.navUnselectedIcon;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      hint: 'Chạm hai lần để chọn',
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
                SvgPicture.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    contentColor,
                    BlendMode.srcIn,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
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
