import 'dart:async';
import 'dart:typed_data';

import 'package:aiseeapp/services/aisee_pcm_audio_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pcmChannel = MethodChannel('flutter_pcm_sound/methods');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pcmChannel, null);
  });

  test('stop waits for in-flight feed before releasing pcm backend', () async {
    final AiseeFlutterPcmAudioPlayer player = AiseeFlutterPcmAudioPlayer();
    final Completer<void> feedStarted = Completer<void>();
    final Completer<void> allowFeedToFinish = Completer<void>();
    int feedCalls = 0;
    int releaseCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pcmChannel, (MethodCall call) async {
          switch (call.method) {
            case 'setup':
            case 'setFeedThreshold':
              return true;
            case 'feed':
              feedCalls += 1;
              if (!feedStarted.isCompleted) {
                feedStarted.complete();
              }
              await allowFeedToFinish.future;
              return true;
            case 'release':
              releaseCalls += 1;
              return true;
            default:
              fail('Unexpected pcm method: ${call.method}');
          }
        });

    await player.enqueuePcm16(_pcmFrame(1200));
    await feedStarted.future;

    final Future<void> stopFuture = player.stop();
    await pumpEventQueue();

    expect(feedCalls, 1);
    expect(releaseCalls, 0);

    allowFeedToFinish.complete();
    await stopFuture;

    expect(releaseCalls, 1);
  });

  test(
    'consecutive assistant chunks reuse pcm backend until explicit stop',
    () async {
      final AiseeFlutterPcmAudioPlayer player = AiseeFlutterPcmAudioPlayer();
      int setupCalls = 0;
      int feedCalls = 0;
      int releaseCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pcmChannel, (MethodCall call) async {
            switch (call.method) {
              case 'setup':
                setupCalls += 1;
                return true;
              case 'setFeedThreshold':
                return true;
              case 'feed':
                feedCalls += 1;
                return true;
              case 'release':
                releaseCalls += 1;
                return true;
              default:
                fail('Unexpected pcm method: ${call.method}');
            }
          });

      await player.enqueuePcm16(_pcmFrame(1200));
      await pumpEventQueue();
      await player.enqueuePcm16(_pcmFrame(2400));
      await pumpEventQueue();
      await player.enqueuePcm16(_pcmFrame(3600));
      await pumpEventQueue();

      expect(setupCalls, 1);
      expect(feedCalls, 3);
      expect(releaseCalls, 0);

      await player.stop(reason: 'test-finished');
      expect(releaseCalls, 1);
    },
  );
}

Uint8List _pcmFrame(int sample, {int samples = 800}) {
  final Uint8List bytes = Uint8List(samples * 2);
  final ByteData data = ByteData.sublistView(bytes);
  for (int index = 0; index < samples; index += 1) {
    data.setInt16(index * 2, sample, Endian.little);
  }
  return bytes;
}
