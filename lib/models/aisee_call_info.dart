import 'aisee_family_member.dart';

class AiseeCallInfo {
  const AiseeCallInfo({
    required this.roomName,
    required this.token,
    required this.callType,
    required this.contact,
  });

  final String roomName;
  final String token;
  final String callType;
  final AiseeFamilyMember contact;
}
