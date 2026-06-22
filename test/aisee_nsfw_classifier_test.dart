import 'package:aiseeapp/services/aisee_nsfw_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiseeNsfwClassifier', () {
    test('treats sexy class as weak evidence below the block threshold', () {
      final double score = AiseeNsfwClassifier.scoreFromModelOutput(<double>[
        0.02,
        0.0,
        0.03,
        0.0,
        0.95,
      ]);

      expect(score, closeTo(0.3325, 0.0001));
      expect(score, lessThan(AiseeNsfwClassifier.defaultThreshold));
    });

    test('keeps explicit classes above the block threshold', () {
      final double score = AiseeNsfwClassifier.scoreFromModelOutput(<double>[
        0.01,
        0.05,
        0.02,
        0.86,
        0.2,
      ]);

      expect(score, closeTo(0.98, 0.0001));
      expect(score, greaterThan(AiseeNsfwClassifier.defaultThreshold));
    });

    test('requires the MobileNet five-class output shape', () {
      expect(
        () => AiseeNsfwClassifier.scoreFromModelOutput(<double>[1, 0]),
        throwsArgumentError,
      );
    });
  });
}
