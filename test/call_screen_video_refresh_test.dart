import 'package:aiseeapp/screens/call_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livekit_client/livekit_client.dart';

void main() {
  test('refreshes video ui for local camera track changes', () {
    expect(
      aiseeShouldRefreshLocalVideoUi(
        isLocalParticipant: true,
        source: TrackSource.camera,
      ),
      isTrue,
    );
  });

  test('ignores non-camera or remote track changes', () {
    expect(
      aiseeShouldRefreshLocalVideoUi(
        isLocalParticipant: false,
        source: TrackSource.camera,
      ),
      isFalse,
    );
    expect(
      aiseeShouldRefreshLocalVideoUi(
        isLocalParticipant: true,
        source: TrackSource.microphone,
      ),
      isFalse,
    );
  });
}
