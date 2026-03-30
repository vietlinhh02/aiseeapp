import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
              'Thoát',
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
                      'Chọn cách bạn dùng AiSee',
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
                      'Dùng hai chấm bên dưới để đổi trang, hoặc vuốt ngang khi không cuộn dọc.',
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
                    badgeLabel: 'Miễn phí hoàn toàn',
                    badgeBackground: _userBadgeBg,
                    badgeTextColor: StyleTokens.textPrimary,
                    title: 'Người dùng',
                    subtitle: 'Dành cho bạn trực tiếp dùng AiSee bằng giọng nói.',
                    bulletPoints: const [
                      'Giao diện ưu tiên giọng nói và thao tác ít nhìn màn hình, phù hợp người suy giảm thị lực.',
                      'Gói người dùng: không phí đăng ký, không hiển thị quảng cáo — trải nghiệm miễn phí cho người dùng chính.',
                      'Dữ liệu bạn cung cấp chỉ phục vụ điều khiển ứng dụng và cải thiện trợ lý theo chính sách quyền riêng tư.',
                    ],
                    accentNote: null,
                    ctaLabel: 'Tiếp tục với tư cách người dùng',
                    onCta: () {
                      _logSelect('user');
                      widget.onSelectRole('user');
                    },
                  ),
                  _RoleSlide(
                    illustrationScale: _illustrationScale,
                    illustrationAsset: 'assets/illustrations/role_family.svg',
                    badgeLabel: 'Có thể có quảng cáo',
                    badgeBackground: _pomSoft,
                    badgeTextColor: _pomText,
                    title: 'Người thân / hỗ trợ',
                    subtitle:
                        'Dành cho người nhà, tình nguyện viên hoặc người đồng hành chăm sóc.',
                    bulletPoints: const [
                      'Bảng điều khiển: theo dõi trạng thái, nhắc lịch, hỗ trợ thiết lập và điều phối từ xa an toàn hơn.',
                      'Gói này có thể hiển thị quảng cáo để góp phần duy trì máy chủ và phát triển tính năng — bạn xác nhận điều này khi chọn vai trò này.',
                      'AiSee hỗ trợ sinh hoạt hằng ngày, không thay cho tư vấn y tế; trường hợp khẩn cấp hãy liên hệ cơ sở y tế.',
                    ],
                    accentNote:
                        'Quảng cáo (nếu có) sẽ được đặt sao cho ít ảnh hưởng luồng chăm sóc; bạn vẫn có thể hỗ trợ dự án bằng cách xem quảng cáo có chủ đích.',
                    ctaLabel: 'Tiếp tục với tư cách người thân / hỗ trợ',
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
                  _pageIndex == 0
                      ? 'Trang 1 / 2 — Người dùng'
                      : 'Trang 2 / 2 — Người thân / hỗ trợ',
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
