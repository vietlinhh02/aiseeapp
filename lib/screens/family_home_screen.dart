import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/aisee_api_models.dart';
import '../theme/style_tokens.dart';
import '../widgets/app_wordmark.dart';

/// Home cho người thân / hỗ trợ (dashboard).
class FamilyHomeScreen extends StatelessWidget {
  const FamilyHomeScreen({
    super.key,
    this.googleUser,
    this.aiseeProfile,
    this.aiseeLoading = false,
    this.aiseeError,
    required this.onSignOut,
  });

  final GoogleSignInAccount? googleUser;
  final AiseeUserProfile? aiseeProfile;
  final bool aiseeLoading;
  final String? aiseeError;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final String? googleName = googleUser?.displayName?.trim();
    final String? profileName = aiseeProfile?.displayName?.trim();
    final String displayName = (googleName != null && googleName.isNotEmpty)
        ? googleName
        : (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (aiseeProfile?.email ?? '—');
    final String emailLine = googleUser?.email ?? aiseeProfile?.email ?? '';

    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(centerTitle: true, title: const AppWordmark(fontSize: 17)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              displayName,
              style: StyleTokens.titleScreen().copyWith(fontSize: 20),
            ),
            if (emailLine.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(emailLine, style: StyleTokens.bodySmall()),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                '[DEBUG] FamilyHome — profile.role=${aiseeProfile?.role ?? "null"}',
                style: StyleTokens.bodySmall().copyWith(
                  color: StyleTokens.linkAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (googleUser == null && aiseeProfile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Phiên đã khôi phục từ lần đăng nhập trước. Đăng nhập Google lại để đồng bộ đầy đủ.',
                style: StyleTokens.legalMuted(),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Tài khoản AiSee',
              style: StyleTokens.separator().copyWith(fontSize: 15),
            ),
            const SizedBox(height: 14),
            if (aiseeLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              ),
              Text(
                'Đang đồng bộ hồ sơ AiSee…',
                style: StyleTokens.bodySmall(),
                textAlign: TextAlign.center,
              ),
            ] else if (aiseeError != null) ...[
              Text(
                aiseeError!,
                style: StyleTokens.bodySmall().copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                googleUser != null
                    ? 'Bạn vẫn đăng nhập Google; đồng bộ với API AiSee chưa thành công.'
                    : 'Đồng bộ với API AiSee chưa thành công.',
                style: StyleTokens.legalMuted(),
              ),
            ] else if (aiseeProfile != null) ...[
              _profileLine(
                'Tên trên hệ thống',
                aiseeProfile!.displayName?.trim().isNotEmpty == true
                    ? aiseeProfile!.displayName!
                    : '—',
              ),
              _profileLine('Email', aiseeProfile!.email),
              _profileLine('Vai trò', _roleLabelVi(aiseeProfile!.role)),
              _profileLine(
                'Tình nguyện viên',
                aiseeProfile!.isVolunteer ? 'Có' : 'Không',
              ),
              _profileLine('Mã người dùng', _shortId(aiseeProfile!.id)),
              if (_formatJoined(aiseeProfile!.createdAt) != null)
                _profileLine(
                  'Tham gia',
                  _formatJoined(aiseeProfile!.createdAt)!,
                ),
            ] else
              Text(
                'Chưa có dữ liệu từ API AiSee.',
                style: StyleTokens.bodySmall(),
              ),
            const SizedBox(height: 32),
            Material(
              color: StyleTokens.buttonPrimary,
              borderRadius: BorderRadius.circular(31),
              child: InkWell(
                borderRadius: BorderRadius.circular(31),
                onTap: onSignOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text('Đăng xuất', style: StyleTokens.socialLabel()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _profileLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: StyleTokens.bodySmall().copyWith(color: StyleTokens.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: StyleTokens.bodySmall().copyWith(
            color: StyleTokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

String _roleLabelVi(String? role) {
  return switch (role) {
    'family' => 'Người thân',
    'user' => 'Người dùng',
    final String r when r.isNotEmpty => r,
    _ => '—',
  };
}

String _shortId(String id) {
  if (id.length <= 12) return id;
  return '${id.substring(0, 8)}…';
}

String? _formatJoined(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    final DateTime dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return iso;
  }
}
