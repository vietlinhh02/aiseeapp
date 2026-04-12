import 'aisee_call_info.dart';
import 'aisee_family_member.dart';

enum AiseeIncomingCallSource { fcm, websocket, callkit }

class AiseeIncomingCall {
  const AiseeIncomingCall({
    required this.callId,
    required this.roomName,
    required this.token,
    required this.callType,
    required this.callerId,
    required this.callerName,
    required this.source,
    required this.receivedAt,
  });

  factory AiseeIncomingCall.fromPayload(
    Map<String, dynamic> payload, {
    required AiseeIncomingCallSource source,
    DateTime? receivedAt,
  }) {
    final Map<String, dynamic> data = _flattenPayload(payload);

    String pick(List<String> keys) {
      for (final String key in keys) {
        final Object? value = data[key];
        if (value == null) {
          continue;
        }
        final String text = value is String ? value : value.toString();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return '';
    }

    final String roomName = pick(const ['room_name', 'roomName', 'room', 'id']);
    final String callId = roomName.isNotEmpty
        ? roomName
        : 'call-${(receivedAt ?? DateTime.now()).millisecondsSinceEpoch}';
    final String callerName = pick(const [
      'caller_name',
      'callerName',
      'name_caller',
      'nameCaller',
    ]);
    final String callType = pick(const ['call_type', 'callType']);
    final String callerId = pick(const [
      'caller_id',
      'callerId',
      'from_user_id',
    ]);
    final String token = pick(const [
      'token',
      'livekit_token',
      'livekitToken',
      'jwt',
    ]);

    return AiseeIncomingCall(
      callId: callId,
      roomName: roomName.isNotEmpty ? roomName : callId,
      token: token,
      callType: callType.isNotEmpty ? callType : 'voice',
      callerId: callerId,
      callerName: callerName.isNotEmpty ? callerName : 'Người gọi',
      source: source,
      receivedAt: receivedAt ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> _flattenPayload(Map<String, dynamic> payload) {
    final Map<String, dynamic> flat = <String, dynamic>{};
    final dynamic nestedMessage = payload['message'];
    if (nestedMessage is Map) {
      nestedMessage.forEach((dynamic key, dynamic value) {
        flat[key.toString()] = value;
      });
    }
    final dynamic extra = payload['extra'];
    if (extra is Map) {
      extra.forEach((dynamic key, dynamic value) {
        flat.putIfAbsent(key.toString(), () => value);
      });
    }
    payload.forEach((String key, dynamic value) {
      flat.putIfAbsent(key, () => value);
    });
    return flat;
  }

  final String callId;
  final String roomName;
  final String token;
  final String callType;
  final String callerId;
  final String callerName;
  final AiseeIncomingCallSource source;
  final DateTime receivedAt;

  bool get isVideo => callType == 'video';

  bool get isValidForAccept => roomName.isNotEmpty && token.isNotEmpty;

  AiseeCallInfo toCallInfo() {
    return AiseeCallInfo(
      roomName: roomName,
      token: token,
      callType: callType,
      contact: AiseeFamilyMember(
        id: callerId.isNotEmpty ? callerId : roomName,
        email: '',
        displayName: callerName,
        role: 'family',
      ),
    );
  }
}
