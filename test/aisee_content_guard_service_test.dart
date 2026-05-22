import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:aiseeapp/services/aisee_content_guard_service.dart';

class _FakeClassifier implements NsfwClassifier {
  final double score;
  int callCount = 0;

  _FakeClassifier(this.score);

  @override
  Future<double> classify(Uint8List argbPixels, int width, int height) async {
    callCount++;
    return score;
  }

  @override
  void dispose() {}
}

void main() {
  const shortInterval = Duration(milliseconds: 50);
  final dummyFrame = (
    pixels: Uint8List.fromList([0, 0, 0, 255]),
    width: 1,
    height: 1,
  );

  test('calls onUnsafeDetected when score exceeds threshold', () async {
    final classifier = _FakeClassifier(0.9);
    final service = AiseeContentGuardService(
      classifier: classifier,
      threshold: 0.7,
      checkInterval: shortInterval,
    );

    var detected = false;
    service.startWithFrameProvider(
      frameProvider: () async => dummyFrame,
      onUnsafeDetected: () => detected = true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));
    service.stop();

    expect(detected, isTrue);
  });

  test(
    'does not call onUnsafeDetected when score is below threshold',
    () async {
      final classifier = _FakeClassifier(0.3);
      final service = AiseeContentGuardService(
        classifier: classifier,
        threshold: 0.7,
        checkInterval: shortInterval,
      );

      var detected = false;
      service.startWithFrameProvider(
        frameProvider: () async => dummyFrame,
        onUnsafeDetected: () => detected = true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));
      service.stop();

      expect(detected, isFalse);
    },
  );

  test('stop() cancels the timer', () async {
    final classifier = _FakeClassifier(0.3);
    final service = AiseeContentGuardService(
      classifier: classifier,
      threshold: 0.7,
      checkInterval: shortInterval,
    );

    service.startWithFrameProvider(
      frameProvider: () async => dummyFrame,
      onUnsafeDetected: () {},
    );

    await Future<void>.delayed(const Duration(milliseconds: 100));
    service.stop();
    final callsAtStop = classifier.callCount;

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(classifier.callCount, equals(callsAtStop));
  });

  test('handles null frame gracefully — classifier never called', () async {
    final classifier = _FakeClassifier(0.9);
    final service = AiseeContentGuardService(
      classifier: classifier,
      threshold: 0.7,
      checkInterval: shortInterval,
    );

    var detected = false;
    service.startWithFrameProvider(
      frameProvider: () async => null,
      onUnsafeDetected: () => detected = true,
    );

    await Future<void>.delayed(const Duration(milliseconds: 200));
    service.stop();

    expect(detected, isFalse);
    expect(classifier.callCount, equals(0));
  });
}
