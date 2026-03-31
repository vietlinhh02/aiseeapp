/// Phản hồi GET /api/v1/volunteers/status
class AiseeVolunteerStatus {
  const AiseeVolunteerStatus({
    required this.isRegistered,
    this.available = false,
  });

  final bool isRegistered;

  /// Chỉ có nghĩa khi [isRegistered] — lấy từ `volunteer.available`.
  final bool available;

  factory AiseeVolunteerStatus.fromJson(Map<String, dynamic> j) {
    final bool reg = j['is_registered'] as bool? ?? false;
    final Object? vol = j['volunteer'];
    if (!reg || vol == null || vol is! Map<String, dynamic>) {
      return const AiseeVolunteerStatus(isRegistered: false, available: false);
    }
    return AiseeVolunteerStatus(
      isRegistered: true,
      available: vol['available'] as bool? ?? false,
    );
  }
}
