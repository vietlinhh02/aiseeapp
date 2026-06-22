import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aisee_reminder_service.dart';

typedef PermissionRequest = Future<void> Function();

class AiseePermissionBootstrapService with WidgetsBindingObserver {
  AiseePermissionBootstrapService._({
    required this.requestMicrophone,
    required this.requestCamera,
    required this.requestNotification,
    required this.requestLocation,
  });

  static const String _bootstrapDoneKey = 'aisee.permission_bootstrap.done';
  static const List<String> runtimePermissionNames = <String>[
    'microphone',
    'camera',
    'notification',
    'location',
  ];

  /// Đệm nhỏ thêm sau khi Activity đã resumed, giúp plugin
  /// permission_handler ổn định trước khi gọi `request()` tiếp theo.
  static const Duration _resumeGracePeriod = Duration(milliseconds: 150);

  static final AiseePermissionBootstrapService instance =
      AiseePermissionBootstrapService._(
        requestMicrophone: () => _requestPermission(Permission.microphone),
        requestCamera: () => _requestPermission(Permission.camera),
        requestNotification: AiseeReminderService.instance.requestPermissions,
        requestLocation: () => _requestPermission(Permission.location),
      );

  factory AiseePermissionBootstrapService.test({
    required PermissionRequest requestMicrophone,
    required PermissionRequest requestCamera,
    required PermissionRequest requestNotification,
    required PermissionRequest requestLocation,
  }) {
    return AiseePermissionBootstrapService._(
      requestMicrophone: requestMicrophone,
      requestCamera: requestCamera,
      requestNotification: requestNotification,
      requestLocation: requestLocation,
    );
  }

  final PermissionRequest requestMicrophone;
  final PermissionRequest requestCamera;
  final PermissionRequest requestNotification;
  final PermissionRequest requestLocation;

  /// Completer đang chờ Activity resumed. Khi dialog hệ thống đóng và app
  /// quay lại foreground, `didChangeAppLifecycleState` sẽ fire `resumed` và
  /// completer này hoàn tất. Đây là tín hiệu đáng tin cậy hơn `delay(350ms)`
  /// cố định — 350ms thường không đủ trên thiết bị chậm khiến các dialog
  /// xin quyền kế tiếp bị bỏ qua cho tới khi đóng mở lại app.
  Completer<void>? _resumeCompleter;
  bool _observerRegistered = false;
  int _activeBootstrap = 0;

  void _ensureObserver() {
    if (_observerRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _observerRegistered = true;
  }

  void _disposeObserver() {
    if (!_observerRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _observerRegistered = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final Completer<void>? pending = _resumeCompleter;
      if (pending != null && !pending.isCompleted) {
        pending.complete();
      }
      _resumeCompleter = null;
    }
  }

  /// Đợi Activity vào trạng thái resumed. Nếu app đang ở resumed (hoặc
  /// chưa từng pause — ví dụ trong test) thì resolve ngay, kèm grace
  /// period nhỏ để ổn định.
  Future<void> _waitForResume() async {
    _ensureObserver();
    final AppLifecycleState? state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      await Future<void>.delayed(_resumeGracePeriod);
      return;
    }
    final Completer<void> completer = Completer<void>();
    _resumeCompleter = completer;
    // Fallback an toàn: nếu vì lý do gì resumed không fire (ví dụ test
    // edge case, môi trường không có WidgetsBinding), tránh treo vĩnh viễn.
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future;
    await Future<void>.delayed(_resumeGracePeriod);
  }

  Future<bool> hasCompletedBootstrap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bootstrapDoneKey) ?? false;
  }

  Future<void> ensureBootstrapped() async {
    if (await hasCompletedBootstrap()) {
      return;
    }
    _activeBootstrap++;
    try {
      await _runSafe(requestMicrophone, 'microphone');
      await _waitForResume();
      await _runSafe(requestCamera, 'camera');
      await _waitForResume();
      await _runSafe(requestNotification, 'notification');
      await _waitForResume();
      await _runSafe(requestLocation, 'location');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bootstrapDoneKey, true);
    } finally {
      _activeBootstrap--;
      if (_activeBootstrap <= 0) {
        _activeBootstrap = 0;
        _disposeObserver();
      }
    }
  }

  Future<void> _runSafe(PermissionRequest request, String label) async {
    try {
      await request();
    } catch (e) {
      debugPrint('[AiSee:PermissionBootstrap] $label request failed: $e');
    }
  }

  static Future<void> _requestPermission(Permission permission) async {
    if (kIsWeb) {
      return;
    }
    final PermissionStatus current = await permission.status;
    if (current.isGranted || current.isPermanentlyDenied) {
      return;
    }
    await permission.request();
  }
}
