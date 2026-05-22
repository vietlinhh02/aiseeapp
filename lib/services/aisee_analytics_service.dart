import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aisee_api_models.dart';

class AiseeAnalyticsEvent {
  const AiseeAnalyticsEvent._();

  static const String signupStarted = 'signup_started';
  static const String signupCompleted = 'signup_completed';
  static const String roleSelected = 'role_selected';
  static const String familyLinkCreated = 'family_link_created';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String firstAiSessionStarted = 'first_ai_session_started';
  static const String firstCameraActivation = 'first_camera_activation';
  static const String firstFamilyDashboardViewed =
      'first_family_dashboard_viewed';
  static const String medicationCreated = 'medication_created';
  static const String medicationTaken = 'medication_taken';
  static const String medicationSkipped = 'medication_skipped';
  static const String sosTriggered = 'sos_triggered';
  static const String dailyBriefOpened = 'daily_brief_opened';
  static const String weeklyReportOpened = 'weekly_report_opened';
  static const String pricingViewed = 'pricing_viewed';
  static const String upgradeClicked = 'upgrade_clicked';
  static const String subscriptionStarted = 'subscription_started';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String quotaExceeded = 'quota_exceeded';
  static const String featureGateSeen = 'feature_gate_seen';

  static const String usageValueOpened = 'usage_value_opened';

  static const String careExportRequested = 'care_export_requested';
  static const String incidentReportOpened = 'incident_report_opened';
  static const String careAlertAcknowledged = 'care_alert_acknowledged';
  static const String careAlertResolved = 'care_alert_resolved';

  static const String aiSessionError = 'ai_session_error';
  static const String toolCallSucceeded = 'tool_call_succeeded';
  static const String toolCallFailed = 'tool_call_failed';
}

abstract class AiseeAnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object> parameters);

  Future<void> setUserId(String? userId);

  Future<void> setUserProperty(String name, String? value);

  Future<void> setScreenName(String screenName);

  Future<void> setCrashKey(String key, Object value);

  Future<void> logCrashMessage(String message);

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  });
}

abstract class AiseeAnalyticsOnceStore {
  Future<bool> hasTracked(String key);

  Future<void> markTracked(String key);
}

class SharedPreferencesAiseeAnalyticsOnceStore
    implements AiseeAnalyticsOnceStore {
  const SharedPreferencesAiseeAnalyticsOnceStore();

  static const String _prefix = 'aisee_analytics_once.';

  @override
  Future<bool> hasTracked(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$key') ?? false;
  }

  @override
  Future<void> markTracked(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', true);
  }
}

class FirebaseAiseeAnalyticsSink implements AiseeAnalyticsSink {
  FirebaseAiseeAnalyticsSink({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logCrashMessage(String message) {
    return _crashlytics.log(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  @override
  Future<void> setCrashKey(String key, Object value) {
    return _crashlytics.setCustomKey(key, value);
  }

  @override
  Future<void> setScreenName(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> setUserId(String? userId) async {
    await Future.wait(<Future<void>>[
      _analytics.setUserId(id: userId),
      _crashlytics.setUserIdentifier(userId ?? ''),
    ]);
  }

  @override
  Future<void> setUserProperty(String name, String? value) {
    return _analytics.setUserProperty(name: name, value: value);
  }
}

class AiseeAnalyticsService {
  AiseeAnalyticsService({
    AiseeAnalyticsSink? sink,
    AiseeAnalyticsOnceStore? onceStore,
  }) : _sink = sink,
       _onceStore =
           onceStore ?? const SharedPreferencesAiseeAnalyticsOnceStore();

  static final AiseeAnalyticsService instance = AiseeAnalyticsService();

  final AiseeAnalyticsOnceStore _onceStore;
  AiseeAnalyticsSink? _sink;
  bool _enabled = false;
  String? _currentScreen;

  NavigatorObserver get navigatorObserver =>
      _AiseeAnalyticsNavigatorObserver(this);

  void configure({AiseeAnalyticsSink? sink, bool enabled = true}) {
    _sink = sink ?? _sink ?? FirebaseAiseeAnalyticsSink();
    _enabled = enabled;
  }

  Future<void> setUser(AiseeUserProfile? profile) async {
    await _guard(() async {
      await _sink?.setUserId(profile?.id);
      await _sink?.setUserProperty('role', profile?.role);
    });
  }

  Future<void> setUserProperty(String name, String? value) async {
    await _guard(() async {
      await _sink?.setUserProperty(name, value);
    });
  }

  Future<void> track(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    await _guard(() async {
      await _sink?.logEvent(name, _sanitizeParameters(parameters));
    });
  }

  Future<void> trackOnce(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
    String? key,
  }) async {
    final String onceKey = key ?? name;
    if (await _onceStore.hasTracked(onceKey)) {
      return;
    }
    await track(name, parameters: parameters);
    await _onceStore.markTracked(onceKey);
  }

  Future<void> trackScreen(String screenName) async {
    _currentScreen = screenName;
    await _guard(() async {
      await _sink?.setScreenName(screenName);
      await _sink?.setCrashKey('current_screen', screenName);
      await _sink?.logCrashMessage('screen:$screenName');
    });
  }

  Future<void> trackToolCall({
    required String toolName,
    required bool success,
    int? durationMs,
    String? errorCode,
  }) {
    return track(
      success
          ? AiseeAnalyticsEvent.toolCallSucceeded
          : AiseeAnalyticsEvent.toolCallFailed,
      parameters: <String, Object?>{
        'tool_name': toolName,
        'duration_ms': durationMs,
        'error_code': errorCode,
        'screen': _currentScreen,
      },
    );
  }

  Future<void> trackAiSessionError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
  }) async {
    await Future.wait(<Future<void>>[
      track(
        AiseeAnalyticsEvent.aiSessionError,
        parameters: <String, Object?>{
          'reason': reason,
          'error_type': error.runtimeType.toString(),
          'screen': _currentScreen,
        },
      ),
      recordError(error, stackTrace ?? StackTrace.current, reason: reason),
    ]);
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    await _guard(() async {
      await _sink?.recordError(error, stackTrace, fatal: fatal, reason: reason);
    });
  }

  void recordFlutterFatalError(FlutterErrorDetails details) {
    unawaited(
      recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: true,
        reason: details.context?.toDescription(),
      ),
    );
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final Map<String, Object> sanitized = <String, Object>{};
    for (final MapEntry<String, Object?> entry in parameters.entries) {
      final Object? value = entry.value;
      if (value == null) {
        continue;
      }
      sanitized[entry.key] = switch (value) {
        bool b => b ? 'true' : 'false',
        DateTime dateTime => dateTime.toIso8601String(),
        Enum enumValue => enumValue.name,
        num n => n,
        String s => s,
        _ => value.toString(),
      };
    }
    return sanitized;
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (!_enabled && _sink == null) {
      return;
    }
    try {
      await action();
    } catch (e, st) {
      debugPrint('[AiSee:Analytics] skipped: $e\n$st');
    }
  }
}

class _AiseeAnalyticsNavigatorObserver extends NavigatorObserver {
  _AiseeAnalyticsNavigatorObserver(this._service);

  final AiseeAnalyticsService _service;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _track(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _track(previousRoute);
    }
  }

  void _track(Route<dynamic> route) {
    final String? name = route.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    unawaited(_service.trackScreen(name));
  }
}
