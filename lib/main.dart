import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'debug/aisee_debug_hud.dart';
import 'debug/aisee_performance_debug.dart';
import 'services/incoming_call_controller.dart';
import 'services/aisee_push_service.dart';
import 'services/aisee_reminder_announcer.dart';
import 'services/aisee_reminder_service.dart';
import 'services/aisee_voice_foreground.dart';
import 'config/aisee_navigator_key.dart';
import 'theme/style_tokens.dart';
import 'widgets/app_bootstrap.dart';
import 'widgets/incoming_call_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[AiSee:Push] Background message: ${message.data}');
  final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
  if (data['type'] == 'incoming_call') {
    await AiseePushService.showIncomingCallUi(data);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AiseeVoiceAssistantForeground.initCommunicationPort();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[AiSee] Firebase init skipped: $e');
  }
  await dotenv.load(fileName: 'assets/app_config.env');
  await AiseeReminderService.instance.init();
  await AiseeReminderAnnouncer.instance.start();
  assert(() {
    final String? lk = dotenv.env['LIVEKIT_URL'];
    if (lk == null || lk.trim().isEmpty) {
      debugPrint(
        '[AiSee] LIVEKIT_URL trống sau khi load assets/app_config.env. '
        'Sửa file nguồn rồi chạy: flutter clean && flutter run '
        '(chỉ hot reload không cập nhật asset).',
      );
    }
    return true;
  }());
  AiseePerformanceDebug.instance.install();
  AiseePushService.instance.attachCallKitListenerEarly();
  runApp(const AiseeApp());
}

class AiseeApp extends StatefulWidget {
  const AiseeApp({super.key});

  @override
  State<AiseeApp> createState() => _AiseeAppState();
}

class _AiseeAppState extends State<AiseeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      AiseePushService.instance.flushPendingCallNavigation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: aiseeNavigatorKey,
      title: 'aisee',
      theme: StyleTokens.lightTheme(),
      showPerformanceOverlay: AiseeDebugConfig.showPerformanceOverlay,
      builder: (BuildContext context, Widget? child) {
        final Widget content = child ?? const SizedBox.shrink();
        final Widget decorated = !AiseeDebugConfig.enabled
            ? content
            : Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[content, const AiseeDebugHud()],
              );
        return IncomingCallOverlayHost(
          controller: AiseeIncomingCallController.instance,
          onAccept: AiseePushService.instance.acceptIncomingCall,
          onDecline: AiseePushService.instance.declineIncomingCall,
          child: decorated,
        );
      },
      home: const AppBootstrap(),
    );
  }

  bool _isForeground(AppLifecycleState state) {
    return state == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AiseeIncomingCallController.instance.setAppForeground(_isForeground(state));
    if (state == AppLifecycleState.resumed) {
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      AiseePushService.instance.flushPendingCallNavigation();
    }
  }
}
