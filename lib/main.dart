import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'debug/aisee_debug_hud.dart';
import 'debug/aisee_performance_debug.dart';
import 'services/aisee_reminder_service.dart';
import 'services/aisee_voice_foreground.dart';
import 'theme/style_tokens.dart';
import 'widgets/app_bootstrap.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();
  debugPrint('[AiSee:Push] Background message: ${message.data}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AiseeVoiceAssistantForeground.initCommunicationPort();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );
  await dotenv.load(fileName: 'assets/app_config.env');
  await AiseeReminderService.instance.init();
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
  runApp(const AiseeApp());
}

class AiseeApp extends StatelessWidget {
  const AiseeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aisee',
      theme: StyleTokens.lightTheme(),
      showPerformanceOverlay: AiseeDebugConfig.showPerformanceOverlay,
      builder: (BuildContext context, Widget? child) {
        if (!AiseeDebugConfig.enabled || child == null) {
          return child ?? const SizedBox.shrink();
        }
        return Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            child,
            const AiseeDebugHud(),
          ],
        );
      },
      home: const AppBootstrap(),
    );
  }
}
