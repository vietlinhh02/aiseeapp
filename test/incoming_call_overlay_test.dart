import 'package:aiseeapp/models/aisee_incoming_call.dart';
import 'package:aiseeapp/services/incoming_call_controller.dart';
import 'package:aiseeapp/widgets/incoming_call_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incoming call payload normalizes alias fields', () {
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      <String, dynamic>{
        'id': 'room-123',
        'callerName': 'Mia',
        'callerId': 'family-1',
        'callType': 'video',
        'livekit_token': 'token-abc',
      },
      source: AiseeIncomingCallSource.fcm,
      receivedAt: DateTime(2026, 4, 1, 10),
    );

    expect(call.callId, 'room-123');
    expect(call.roomName, 'room-123');
    expect(call.callerName, 'Mia');
    expect(call.callerId, 'family-1');
    expect(call.callType, 'video');
    expect(call.token, 'token-abc');
    expect(call.isValidForAccept, isTrue);
  });

  test('incoming call payload unwraps websocket message body', () {
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      <String, dynamic>{
        'type': 'incoming_call',
        'message': <String, dynamic>{
          'caller_name': 'Mia',
          'caller_id': 'family-1',
          'room_name': 'call-1234',
          'call_type': 'voice',
          'token': 'token-from-ws',
        },
      },
      source: AiseeIncomingCallSource.websocket,
      receivedAt: DateTime(2026, 4, 1, 10),
    );

    expect(call.roomName, 'call-1234');
    expect(call.callerName, 'Mia');
    expect(call.token, 'token-from-ws');
    expect(call.isValidForAccept, isTrue);
  });

  test('controller only shows overlay while app is foreground', () {
    final AiseeIncomingCallController controller =
        AiseeIncomingCallController();
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      <String, dynamic>{
        'room_name': 'room-foreground',
        'caller_name': 'Mia',
        'token': 'token-foreground',
      },
      source: AiseeIncomingCallSource.websocket,
      receivedAt: DateTime(2026, 4, 1, 10),
    );

    controller.setAppForeground(false);
    controller.showIncomingCall(call);
    expect(controller.shouldShowOverlay, isFalse);

    controller.setAppForeground(true);
    expect(controller.shouldShowOverlay, isTrue);

    controller.hideIncomingCall();
    expect(controller.currentCall, isNull);
  });

  testWidgets('overlay renders incoming call and forwards accept/decline', (
    WidgetTester tester,
  ) async {
    final AiseeIncomingCallController controller =
        AiseeIncomingCallController();
    AiseeIncomingCall? acceptedCall;
    AiseeIncomingCall? declinedCall;

    await tester.pumpWidget(
      MaterialApp(
        home: IncomingCallOverlayHost(
          controller: controller,
          onAccept: (AiseeIncomingCall call) async {
            acceptedCall = call;
          },
          onDecline: (AiseeIncomingCall call) async {
            declinedCall = call;
          },
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    controller.showIncomingCall(
      AiseeIncomingCall.fromPayload(
        <String, dynamic>{
          'room_name': 'room-ui',
          'caller_name': 'Mia',
          'caller_id': 'family-ui',
          'call_type': 'voice',
          'token': 'token-ui',
        },
        source: AiseeIncomingCallSource.websocket,
        receivedAt: DateTime(2026, 4, 1, 10),
      ),
    );
    await tester.pump();

    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Cuộc gọi thoại đến'), findsOneWidget);

    await tester.tap(find.text('Nghe'));
    await tester.pump();

    expect(acceptedCall?.roomName, 'room-ui');
    expect(find.text('Mia'), findsNothing);

    controller.showIncomingCall(
      AiseeIncomingCall.fromPayload(
        <String, dynamic>{
          'room_name': 'room-decline',
          'caller_name': 'Linh',
          'token': 'token-decline',
        },
        source: AiseeIncomingCallSource.fcm,
        receivedAt: DateTime(2026, 4, 1, 10),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Từ chối'));
    await tester.pump();

    expect(declinedCall?.roomName, 'room-decline');
    expect(find.text('Linh'), findsNothing);
  });
}
