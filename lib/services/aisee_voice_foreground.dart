import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Entry-point cho isolate foreground (Android).
@pragma('vm:entry-point')
void aiseeVoiceForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(AiseeVoiceForegroundTaskHandler());
}

class AiseeVoiceForegroundTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Foreground Service (Android) khi trợ lý giọng nói đang kết nối — giảm kill WebSocket khi tắt màn hình.
abstract final class AiseeVoiceAssistantForeground {
  static bool _inited = false;

  static StateError _serviceRequestFailure(String action, Object error) {
    return StateError('AiSee foreground $action failed: $error');
  }

  /// Gọi trong [main] ngay sau [WidgetsFlutterBinding.ensureInitialized].
  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static bool get _useAndroidFg =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void _ensurePluginInit() {
    if (!_useAndroidFg || _inited) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aisee_voice_session',
        channelName: 'Trợ lý AiSee',
        channelDescription: 'Giữ kết nối khi màn hình tắt.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _inited = true;
  }

  /// Gọi sau khi đã [Room.connect] và bật mic thành công.
  static Future<void> ensureStartedAfterConnected() async {
    if (!_useAndroidFg) return;
    _ensurePluginInit();
    final NotificationPermission perm =
        await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }
    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
          serviceId: 9081,
          serviceTypes: <ForegroundServiceTypes>[
            ForegroundServiceTypes.microphone,
            ForegroundServiceTypes.mediaPlayback,
          ],
          notificationTitle: 'AiSee đang hoạt động',
          notificationText: 'Trợ lý giọng nói đang bật — chạm để mở app',
          callback: aiseeVoiceForegroundTaskCallback,
        );
    if (result case ServiceRequestFailure(:final Object error)) {
      throw _serviceRequestFailure('start', error);
    }
  }

  /// Gọi khi ngắt phòng / thoát phiên giọng nói.
  static Future<void> ensureStopped() async {
    if (!_useAndroidFg) return;
    if (!await FlutterForegroundTask.isRunningService) return;
    final ServiceRequestResult result =
        await FlutterForegroundTask.stopService();
    if (result case ServiceRequestFailure(:final Object error)) {
      throw _serviceRequestFailure('stop', error);
    }
  }
}
