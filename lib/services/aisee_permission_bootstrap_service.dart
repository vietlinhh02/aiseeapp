import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aisee_reminder_service.dart';

typedef PermissionRequest = Future<void> Function();

class AiseePermissionBootstrapService {
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

  Future<bool> hasCompletedBootstrap() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bootstrapDoneKey) ?? false;
  }

  Future<void> ensureBootstrapped() async {
    if (await hasCompletedBootstrap()) {
      return;
    }
    await _runSafe(requestMicrophone, 'microphone');
    await _runSafe(requestCamera, 'camera');
    await _runSafe(requestNotification, 'notification');
    await _runSafe(requestLocation, 'location');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bootstrapDoneKey, true);
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
