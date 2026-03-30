import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo chữ G đa màu của Google (SVG nguồn mở, xem `assets/branding/`).
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/google_g.svg',
      width: size,
      height: size,
      semanticsLabel: 'Google',
    );
  }
}
