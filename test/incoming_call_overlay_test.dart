import 'package:aiseeapp/generated/l10n/app_localizations.dart';
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
        'caller_avatar_url': 'https://example.com/mia.png',
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
    expect(call.callerAvatarUrl, 'https://example.com/mia.png');
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

  test('controller clears only the matching incoming call room', () {
    final AiseeIncomingCallController controller =
        AiseeIncomingCallController();
    final AiseeIncomingCall call = AiseeIncomingCall.fromPayload(
      <String, dynamic>{
        'room_name': 'room-active',
        'caller_name': 'Mia',
        'token': 'token-active',
      },
      source: AiseeIncomingCallSource.websocket,
      receivedAt: DateTime(2026, 4, 1, 10),
    );

    controller.showIncomingCall(call);
    controller.hideIncomingCallForRoom('room-other');
    expect(controller.currentCall?.roomName, 'room-active');

    controller.hideIncomingCallForRoom('room-active');
    expect(controller.currentCall, isNull);
  });

  testWidgets('overlay renders caller avatar when provided', (
    WidgetTester tester,
  ) async {
    final AiseeIncomingCallController controller =
        AiseeIncomingCallController();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IncomingCallOverlayHost(
          controller: controller,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    controller.showIncomingCall(
      AiseeIncomingCall.fromPayload(
        <String, dynamic>{
          'room_name': 'room-avatar',
          'caller_name': 'Mia',
          'caller_avatar_url': 'https://example.com/mia.png',
          'token': 'token-avatar',
        },
        source: AiseeIncomingCallSource.websocket,
        receivedAt: DateTime(2026, 4, 1, 10),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Mia'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    controller.dispose();
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
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    await tester.pump(const Duration(milliseconds: 240));

    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Cuộc gọi thoại đến'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_rounded));
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

    await tester.tap(find.byIcon(Icons.call_end_rounded));
    await tester.pump();

    expect(declinedCall?.roomName, 'room-decline');
    expect(find.text('Linh'), findsNothing);

    controller.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('overlay works from MaterialApp builder', (
    WidgetTester tester,
  ) async {
    final AiseeIncomingCallController controller =
        AiseeIncomingCallController();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) {
          return IncomingCallOverlayHost(
            controller: controller,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );

    controller.showIncomingCall(
      AiseeIncomingCall.fromPayload(
        <String, dynamic>{
          'room_name': 'room-builder',
          'caller_name': 'Mia',
          'token': 'token-builder',
        },
        source: AiseeIncomingCallSource.websocket,
        receivedAt: DateTime(2026, 4, 1, 10),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Mia'), findsOneWidget);

    controller.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });
}
