import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';

/// Sau Google Sign-In: 2 trang vuốt ngang, minh họa SVG + mô tả chi tiết từng vai trò.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({
    super.key,
    required this.googleUser,
    required this.onSelectRole,
    required this.onSignOut,
  });

  final GoogleSignInAccount googleUser;
  final void Function(String role) onSelectRole;
  final VoidCallback onSignOut;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  static const Color _userBadgeBg = Color(0xFFEEEEEE);
  static const Color _pomSoft = Color(0xFFFFE5E0);
  static const Color _pomText = Color(0xFFC52B10);

  /// SVG hơi nhỏ hơn bản full width (1.0 = như AspectRatio cũ).
  static const double _illustrationScale = 0.88;

  late final PageController _pageController;
  int _pageIndex = 0;

  /// Khi đang cuộn dọc nội dung trang, tắt vuốt ngang PageView để khỏi nhầm gesture.
  bool _lockPageSwipe = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _logSelect(String role) {
    if (kDebugMode) {
      debugPrint('[AiSeeAuth] RoleSelection: chọn $role');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String? name = widget.googleUser.displayName?.trim();
    final String line = (name != null && name.isNotEmpty)
        ? name
        : widget.googleUser.email;

    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        centerTitle: true,
        title: const AppWordmark(fontSize: 17),
        actions: [
          TextButton(
            onPressed: widget.onSignOut,
            child: Text(
              l.roleAppBarExit,
              style: StyleTokens.bodySmall().copyWith(
                color: StyleTokens.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Column(
                children: [
                  Text(
                    l.roleSelectionTitle,
                    style: StyleTokens.titleScreen(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line,
                    style: StyleTokens.bodySmall().copyWith(
                      color: StyleTokens.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.roleSelectionHelp,
                    style: StyleTokens.legalMuted(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification n) {
                  if (n.metrics.axis != Axis.vertical) return false;
                  if (n is ScrollStartNotification) {
                    if (!_lockPageSwipe) {
                      setState(() => _lockPageSwipe = true);
                    }
                  } else if (n is ScrollEndNotification) {
                    if (_lockPageSwipe) {
                      setState(() => _lockPageSwipe = false);
                    }
                  }
                  return false;
                },
                child: PageView(
                  controller: _pageController,
                  physics: _lockPageSwipe
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  onPageChanged: (int i) => setState(() => _pageIndex = i),
                  children: [
                    _RoleSlide(
                      illustrationScale: _illustrationScale,
                      illustrationAsset: 'assets/illustrations/role_user.svg',
                      badgeLabel: l.roleUserBadge,
                      badgeBackground: _userBadgeBg,
                      badgeTextColor: StyleTokens.textPrimary,
                      title: l.roleUserTitle,
                      subtitle: l.roleUserSubtitle,
                      bulletPoints: <String>[
                        l.roleUserBullet1,
                        l.roleUserBullet2,
                        l.roleUserBullet3,
                      ],
                      accentNote: null,
                      ctaLabel: l.roleUserCta,
                      onCta: () {
                        _logSelect('user');
                        widget.onSelectRole('user');
                      },
                    ),
                    _RoleSlide(
                      illustrationScale: _illustrationScale,
                      illustrationAsset: 'assets/illustrations/role_family.svg',
                      badgeLabel: l.roleFamilyBadge,
                      badgeBackground: _pomSoft,
                      badgeTextColor: _pomText,
                      title: l.roleFamilyTitle,
                      subtitle: l.roleFamilySubtitle,
                      bulletPoints: <String>[
                        l.roleFamilyBullet1,
                        l.roleFamilyBullet2,
                        l.roleFamilyBullet3,
                      ],
                      accentNote: l.roleFamilyAccentNote,
                      ctaLabel: l.roleFamilyCta,
                      onCta: () {
                        _logSelect('family');
                        widget.onSelectRole('family');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(2, (int i) {
                final bool active = i == _pageIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: active
                            ? StyleTokens.textPrimary
                            : StyleTokens.textMuted.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              child: Text(
                _pageIndex == 0 ? l.rolePagerUserPage : l.rolePagerFamilyPage,
                style: StyleTokens.legalMuted(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSlide extends StatelessWidget {
  const _RoleSlide({
    required this.illustrationScale,
    required this.illustrationAsset,
    required this.badgeLabel,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.title,
    required this.subtitle,
    required this.bulletPoints,
    required this.accentNote,
    required this.ctaLabel,
    required this.onCta,
  });

  final double illustrationScale;
  final String illustrationAsset;
  final String badgeLabel;
  final Color badgeBackground;
  final Color badgeTextColor;
  final String title;
  final String subtitle;
  final List<String> bulletPoints;
  final String? accentNote;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxW = (constraints.maxWidth - 48) * illustrationScale;
        final double illoH = maxW * (320 / 360);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: maxW,
                    height: illoH,
                    child: SvgPicture.asset(
                      illustrationAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: badgeBackground == const Color(0xFFEEEEEE)
                        ? Border.all(color: const Color(0xFFE0E0E0))
                        : null,
                  ),
                  child: Text(
                    badgeLabel,
                    style: StyleTokens.bodySmall().copyWith(
                      color: badgeTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: StyleTokens.titleScreen().copyWith(fontSize: 22),
              ),
              const SizedBox(height: 18),
              Material(
                color: StyleTokens.buttonPrimary,
                borderRadius: BorderRadius.circular(31),
                child: InkWell(
                  borderRadius: BorderRadius.circular(31),
                  onTap: onCta,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Center(
                      child: Text(
                        ctaLabel,
                        style: StyleTokens.socialLabel(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                subtitle,
                style: StyleTokens.bodySmall().copyWith(
                  color: StyleTokens.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              ...bulletPoints.map(
                (String line) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text.rich(
                    TextSpan(
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: StyleTokens.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: '•  ',
                          style: StyleTokens.bodySmall().copyWith(
                            fontSize: 13,
                            height: 1.45,
                            color: StyleTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(text: line),
                      ],
                    ),
                  ),
                ),
              ),
              if (accentNote != null) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    accentNote!,
                    style: StyleTokens.bodySmall().copyWith(
                      color: StyleTokens.textMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
