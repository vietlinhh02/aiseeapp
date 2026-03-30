class AiseeFamilyMember {
  const AiseeFamilyMember({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String role;
  final String? avatarUrl;

  factory AiseeFamilyMember.fromJson(Map<String, dynamic> j) {
    return AiseeFamilyMember(
      id: j['id'] as String,
      email: j['email'] as String? ?? '',
      displayName: j['display_name'] as String?,
      role: j['role'] as String? ?? 'family',
      avatarUrl: j['avatar_url'] as String?,
    );
  }

  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : email;
}
