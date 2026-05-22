import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/aisee_locale_controller.dart';
import 'debug/aisee_debug_hud.dart';
import 'debug/aisee_performance_debug.dart';
import 'generated/l10n/app_localizations.dart';
import 'models/aisee_reminder.dart';
import 'screens/reminders_screen.dart';
import 'services/aisee_analytics_service.dart';
import 'services/incoming_call_controller.dart';
import 'services/in_app_message_controller.dart';
import 'services/aisee_push_service.dart';
import 'services/aisee_reminder_announcer.dart';
import 'services/aisee_reminder_service.dart';
import 'services/aisee_voice_foreground.dart';
import 'config/aisee_navigator_key.dart';
import 'theme/style_tokens.dart';
import 'widgets/app_bootstrap.dart';
import 'widgets/in_app_message_overlay.dart';
import 'widgets/incoming_call_overlay.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[AiSee:Push] Background message: ${message.data}');
  final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
  if (data['type'] == 'incoming_call' || data['type'] == 'volunteer_match') {
    await AiseePushService.showIncomingCallUi(data);
  } else if (data['type'] == 'call_ended') {
    await AiseePushService.endIncomingCallUi(data);
  }
}

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AiseeVoiceAssistantForeground.initCommunicationPort();
      try {
        await Firebase.initializeApp();
        AiseeAnalyticsService.instance.configure();
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        debugPrint('[AiSee] Firebase init skipped: $e');
      }
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AiseeAnalyticsService.instance.recordFlutterFatalError(details);
      };
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        unawaited(
          AiseeAnalyticsService.instance.recordError(
            error,
            stack,
            fatal: true,
            reason: 'platform_dispatcher',
          ),
        );
        return true;
      };
      await dotenv.load(fileName: 'assets/app_config.env');
      await AiseeLocaleController.instance.load();
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
    },
    (Object error, StackTrace stack) {
      unawaited(
        AiseeAnalyticsService.instance.recordError(
          error,
          stack,
          fatal: true,
          reason: 'run_zoned_guarded',
        ),
      );
    },
  );
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
    AiseeReminderService.instance.setNotificationTapHandler(
      _openReminderFromNotification,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      AiseePushService.instance.flushPendingCallNavigation();
      AiseeReminderService.instance.flushPendingNotificationNavigation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AiseeLocaleController.instance,
      builder: (BuildContext context, Locale locale, _) {
        return MaterialApp(
          navigatorKey: aiseeNavigatorKey,
          title: 'aisee',
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AiseeLocaleController.supportedLocales,
          theme: StyleTokens.lightTheme(),
          showPerformanceOverlay: AiseeDebugConfig.showPerformanceOverlay,
          navigatorObservers: <NavigatorObserver>[
            AiseeAnalyticsService.instance.navigatorObserver,
          ],
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
            final Widget messageOverlay = InAppMessageOverlayHost(
              controller: AiseeInAppMessageController.instance,
              child: decorated,
            );
            return IncomingCallOverlayHost(
              controller: AiseeIncomingCallController.instance,
              onAccept: AiseePushService.instance.acceptIncomingCall,
              onDecline: AiseePushService.instance.declineIncomingCall,
              child: messageOverlay,
            );
          },
          home: const AppBootstrap(),
        );
      },
    );
  }

  bool _isForeground(AppLifecycleState state) {
    return state == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AiseeIncomingCallController.instance.setAppForeground(_isForeground(state));
    AiseeInAppMessageController.instance.setAppForeground(_isForeground(state));
    if (state == AppLifecycleState.resumed) {
      unawaited(AiseePushService.instance.syncActiveAcceptedCall());
      AiseePushService.instance.flushPendingCallNavigation();
      AiseeReminderService.instance.flushPendingNotificationNavigation();
    }
  }

  bool _openReminderFromNotification(AiseeReminderNotificationPayload payload) {
    final BuildContext? ctx = aiseeNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return false;
    }
    final NavigatorState? nav = Navigator.maybeOf(ctx, rootNavigator: true);
    if (nav == null) {
      return false;
    }
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => RemindersScreen(
          initialFilter: _reminderFilterForType(payload.type),
          highlightedReminderId: payload.reminderId,
        ),
      ),
    );
    return true;
  }

  ReminderFilter _reminderFilterForType(AiseeReminderType type) {
    return switch (type) {
      AiseeReminderType.medication => ReminderFilter.medication,
      AiseeReminderType.appointment => ReminderFilter.appointment,
    };
  }
}
