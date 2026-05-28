class AiseeCareGroupPerson {
  const AiseeCareGroupPerson({
    required this.id,
    required this.email,
    required this.accountRole,
    required this.groupRole,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String accountRole;
  final String groupRole;
  final String? displayName;
  final String? avatarUrl;

  factory AiseeCareGroupPerson.fromJson(Map<String, dynamic> json) {
    return AiseeCareGroupPerson(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      accountRole: json['account_role'] as String? ?? '',
      groupRole: json['group_role'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'account_role': accountRole,
    'group_role': groupRole,
    'display_name': displayName,
    'avatar_url': avatarUrl,
  };

  String get label =>
      displayName?.trim().isNotEmpty == true ? displayName! : email;

  bool get isOwner => groupRole == 'owner';
  bool get isFamilyMember => groupRole != 'cared_user';
}

class AiseeCurrentGroup {
  const AiseeCurrentGroup({
    required this.id,
    required this.name,
    required this.ownerUserId,
    required this.currentUserRole,
    required this.canManageGroup,
    required this.canManageBilling,
    required this.familyMembers,
    required this.caredUsers,
  });

  final String id;
  final String name;
  final String ownerUserId;
  final String currentUserRole;
  final bool canManageGroup;
  final bool canManageBilling;
  final List<AiseeCareGroupPerson> familyMembers;
  final List<AiseeCareGroupPerson> caredUsers;

  factory AiseeCurrentGroup.fromJson(Map<String, dynamic> json) {
    List<AiseeCareGroupPerson> parsePeople(String key) {
      final Object? raw = json[key];
      if (raw is! List<dynamic>) {
        return const <AiseeCareGroupPerson>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(AiseeCareGroupPerson.fromJson)
          .toList();
    }

    return AiseeCurrentGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'AiSee Care Group',
      ownerUserId: json['owner_user_id'] as String? ?? '',
      currentUserRole: json['current_user_role'] as String? ?? '',
      canManageGroup: json['can_manage_group'] as bool? ?? false,
      canManageBilling: json['can_manage_billing'] as bool? ?? false,
      familyMembers: parsePeople('family_members'),
      caredUsers: parsePeople('cared_users'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'owner_user_id': ownerUserId,
    'current_user_role': currentUserRole,
    'can_manage_group': canManageGroup,
    'can_manage_billing': canManageBilling,
    'family_members': familyMembers.map((e) => e.toJson()).toList(),
    'cared_users': caredUsers.map((e) => e.toJson()).toList(),
  };
}
