// Kiểu dữ liệu JSON từ API AiSee (theo docs dự án).

class AiseeApiException implements Exception {
  AiseeApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// HTTP 402 — phản hồi quota từ backend (billing / care).
class AiseeQuotaApiException extends AiseeApiException {
  AiseeQuotaApiException(
    super.message, {
    super.code,
    this.usageType,
    this.requiredAmount,
    this.remaining,
    this.planCode,
    this.resetPeriod,
  });

  final String? usageType;
  final double? requiredAmount;
  final double? remaining;
  final String? planCode;
  final String? resetPeriod;
}

/// JWT access + refresh sau khi đổi Google `id_token`.
class AiseeAuthTokens {
  const AiseeAuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

/// User trong phản hồi `POST /auth/google` (dùng để kiểm tra JSON).
class AiseeUserBrief {
  const AiseeUserBrief({
    required this.id,
    required this.email,
    this.displayName,
    this.role,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? role;

  factory AiseeUserBrief.fromJson(Map<String, dynamic> j) {
    return AiseeUserBrief(
      id: j['id'] as String,
      email: j['email'] as String,
      displayName: j['display_name'] as String?,
      role: j['role'] as String?,
    );
  }
}

/// Hồ sơ đầy đủ từ `GET /users/me`.
class AiseeUserProfile {
  const AiseeUserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.role,
    this.isVolunteer = false,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? role;
  final bool isVolunteer;
  final String? avatarUrl;
  final String? createdAt;

  /// Lưu cache hiển thị (SharedPreferences); khớp khóa với [fromJson].
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_volunteer': isVolunteer,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
    };
  }

  factory AiseeUserProfile.fromJson(Map<String, dynamic> j) {
    final Object? rawId = j['id'];
    final String id = rawId is String
        ? rawId
        : (rawId == null ? '' : rawId.toString());
    if (id.isEmpty) {
      throw AiseeApiException('Phản hồi /users/me thiếu id');
    }
    return AiseeUserProfile(
      id: id,
      email: j['email'] as String? ?? '',
      displayName: _emptyToNull(j['display_name'] as String?),
      role: j['role'] as String?,
      isVolunteer: j['is_volunteer'] as bool? ?? false,
      avatarUrl: _emptyToNull(j['avatar_url'] as String?),
      createdAt: _isoTime(j['created_at']),
    );
  }

  static String? _emptyToNull(String? s) {
    if (s == null || s.isEmpty) return null;
    return s;
  }

  /// Go `timestamptz` có thể là chuỗi hoặc object; chỉ lấy chuỗi hiển thị.
  static String? _isoTime(Object? v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }
}
