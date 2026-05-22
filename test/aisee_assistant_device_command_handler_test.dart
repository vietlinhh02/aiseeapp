import 'package:aiseeapp/services/aisee_ai_session.dart';
import 'package:aiseeapp/services/aisee_assistant_device_command_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start_call delegates to injected launcher callback', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler(
          onStartCall: (Map<String, dynamic> params) async {
            expect(params['room_name'], 'call-1');
            return <String, Object?>{'status': 'answered'};
          },
        );

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-1',
        name: 'start_call',
        params: <String, dynamic>{'room_name': 'call-1', 'token': 'abc'},
      ),
    );

    expect(result, <String, Object?>{'status': 'answered'});
    await handler.dispose();
  });

  test('start_call returns unavailable when launcher is missing', () async {
    final AiseeDefaultAssistantDeviceCommandHandler handler =
        AiseeDefaultAssistantDeviceCommandHandler();

    final Map<String, Object?> result = await handler.handle(
      const AiseeAiDeviceCommandRequest(
        requestId: 'tool-2',
        name: 'start_call',
        params: <String, dynamic>{'room_name': 'call-2', 'token': 'def'},
      ),
    );

    expect(result['status'], 'unavailable');
    await handler.dispose();
  });
}
