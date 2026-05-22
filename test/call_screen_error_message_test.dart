import 'package:aiseeapp/models/aisee_api_models.dart';
import 'package:aiseeapp/screens/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('speaker defaults on for both voice and video calls', () {
    expect(aiseeShouldEnableSpeakerByDefault('voice'), isTrue);
    expect(aiseeShouldEnableSpeakerByDefault('video'), isTrue);
  });

  test('call join message prefers API error text', () {
    expect(
      aiseeCallJoinErrorMessage(AiseeApiException('Token cuộc gọi đã hết hạn')),
      'Token cuộc gọi đã hết hạn',
    );
  });

  test('call join message falls back for unknown errors', () {
    expect(
      aiseeCallJoinErrorMessage(Exception('socket failed')),
      'callJoinFailed',
    );
  });
}
