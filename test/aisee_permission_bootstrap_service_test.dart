import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aiseeapp/services/aisee_permission_bootstrap_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('bootstrap requests core permissions in fixed order once', () async {
    final List<String> calls = <String>[];
    final AiseePermissionBootstrapService service =
        AiseePermissionBootstrapService.test(
          requestMicrophone: () async => calls.add('microphone'),
          requestCamera: () async => calls.add('camera'),
          requestNotification: () async => calls.add('notification'),
          requestLocation: () async => calls.add('location'),
        );

    await service.ensureBootstrapped();
    await service.ensureBootstrapped();

    expect(calls, <String>['microphone', 'camera', 'notification', 'location']);
    expect(await service.hasCompletedBootstrap(), isTrue);
  });

  test('bootstrap continues when one permission throws', () async {
    final List<String> calls = <String>[];
    final AiseePermissionBootstrapService service =
        AiseePermissionBootstrapService.test(
          requestMicrophone: () async => calls.add('microphone'),
          requestCamera: () async {
            calls.add('camera');
            throw StateError('camera denied');
          },
          requestNotification: () async => calls.add('notification'),
          requestLocation: () async => calls.add('location'),
        );

    await service.ensureBootstrapped();

    expect(calls, <String>['microphone', 'camera', 'notification', 'location']);
    expect(await service.hasCompletedBootstrap(), isTrue);
  });

  test('bootstrap service only covers the four core runtime permissions', () {
    expect(AiseePermissionBootstrapService.runtimePermissionNames, <String>[
      'microphone',
      'camera',
      'notification',
      'location',
    ]);
  });
}
