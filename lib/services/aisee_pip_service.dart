import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AiseePipService {
  AiseePipService._();

  static final AiseePipService instance = AiseePipService._();

  static const MethodChannel _channel = MethodChannel('com.aisee.aiseeapp/pip');

  final ValueNotifier<bool> isInPipMode = ValueNotifier<bool>(false);

  bool _initialized = false;

  void init() {
    if (_initialized || kIsWeb) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> setVideoCallActive(bool active) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setVideoCallActive', <String, dynamic>{
        'active': active,
      });
    } catch (e) {
      debugPrint('[AiSee:Pip] setVideoCallActive error: $e');
    }
  }

  Future<void> enterPip() async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('enterPip');
    } catch (e) {
      debugPrint('[AiSee:Pip] enterPip error: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPipModeChanged':
        final bool inPip = call.arguments['isInPip'] as bool? ?? false;
        isInPipMode.value = inPip;
    }
  }
}
