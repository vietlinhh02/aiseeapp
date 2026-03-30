import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/style_tokens.dart';

class UserToolsTab extends StatelessWidget {
  const UserToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Công cụ. Camera và Danh bạ gọi điện.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Text(
            'Công cụ',
            style: StyleTokens.titleScreen().copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Mở nhanh khi ồn ào, không tiện ra lệnh giọng nói.',
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _BigToolTile(
            iconAsset: 'assets/icons/nav/ic_camera.svg',
            title: 'Camera — AI nhìn hộ',
            subtitle: 'Mở camera để AiSee mô tả cảnh trước mắt bạn.',
            semanticsLabel: 'Camera. AI nhìn hộ.',
            onTap: () => HapticFeedback.lightImpact(),
          ),
          const SizedBox(height: 16),
          _BigToolTile(
            iconAsset: 'assets/icons/nav/ic_3user.svg',
            title: 'Danh bạ người thân',
            subtitle: 'Gọi nhanh số đã lưu.',
            semanticsLabel: 'Danh bạ người thân. Gọi điện nhanh.',
            onTap: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
    );
  }
}

class _BigToolTile extends StatelessWidget {
  const _BigToolTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            child: Row(
              children: [
                ClipRect(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: SvgPicture.asset(
                      iconAsset,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.navSelectedPill,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: StyleTokens.titleScreen().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 11,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: SvgPicture.asset(
                    'assets/icons/nav/ic_arrow_right.svg',
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      StyleTokens.textMuted,
                      BlendMode.srcIn,
                    ),
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
