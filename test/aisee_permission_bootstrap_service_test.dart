import 'package:flutter/widgets.dart';
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

  test(
    'bootstrap proceeds when app has not been paused yet (test env)',
    () async {
      // Trong môi trường test, lifecycleState ban đầu là null (chưa resume
      // lần nào). Service phải vẫn chạy qua hết 4 quyền mà không treo.
      final List<String> calls = <String>[];
      final AiseePermissionBootstrapService service =
          AiseePermissionBootstrapService.test(
            requestMicrophone: () async => calls.add('microphone'),
            requestCamera: () async => calls.add('camera'),
            requestNotification: () async => calls.add('notification'),
            requestLocation: () async => calls.add('location'),
          );

      await service.ensureBootstrapped();

      expect(
        calls,
        <String>['microphone', 'camera', 'notification', 'location'],
      );
    },
  );

  test(
    'bootstrap waits for app resume between consecutive permission requests',
    () async {
      // Mô phỏng: khi đang chờ permission thứ 2, app đang ở trạng thái
      // paused (vì dialog hệ thống che Activity). Service phải đợi resumed
      // mới gọi request tiếp theo. Đây chính là fix bug "thoát app vào lại
      // mới thấy dialog tiếp theo".
      final List<String> calls = <String>[];
      final AiseePermissionBootstrapService service =
          AiseePermissionBootstrapService.test(
            requestMicrophone: () async {
              calls.add('microphone');
              // Mô phỏng dialog hệ thống pause Activity.
              await _simulatePause();
            },
            requestCamera: () async {
              calls.add('camera');
              await _simulatePause();
            },
            requestNotification: () async {
              calls.add('notification');
              await _simulatePause();
            },
            requestLocation: () async {
              calls.add('location');
              await _simulatePause();
            },
          );

      final Future<void> done = service.ensureBootstrapped();

      // Trước khi resumed, service không được phép gọi tiếp request thứ 2.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls, <String>['microphone']);

      // Mô phỏng user đóng dialog → app resumed. Sau đó cần đợi thêm
      // grace period (150ms) trước khi request kế tiếp được phép chạy.
      _simulateResume();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(calls, <String>['microphone', 'camera']);

      _simulateResume();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(calls, <String>['microphone', 'camera', 'notification']);

      _simulateResume();
      await done;
      expect(
        calls,
        <String>['microphone', 'camera', 'notification', 'location'],
      );
    },
  );
}

Future<void> _simulatePause() async {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void _simulateResume() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.instance;
  binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}
