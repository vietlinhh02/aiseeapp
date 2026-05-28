import 'package:aiseeapp/screens/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assistant call result marks immediate remote hangup', () {
    expect(
      aiseeAssistantCallEndStatus(
        answered: true,
        remoteEnded: true,
        duration: const Duration(seconds: 1),
      ),
      'remote_ended_quickly',
    );
  });

  test('assistant call result keeps normal remote hangup separate', () {
    expect(
      aiseeAssistantCallEndStatus(
        answered: true,
        remoteEnded: true,
        duration: const Duration(seconds: 10),
      ),
      'remote_ended',
    );
  });

  test('assistant call result marks local ended calls', () {
    expect(
      aiseeAssistantCallEndStatus(
        answered: true,
        remoteEnded: false,
        duration: const Duration(seconds: 10),
      ),
      'ended',
    );
  });
}
