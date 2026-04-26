import 'package:aiseeapp/services/aisee_analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiseeAnalyticsService', () {
    test('tracks product events with sanitized parameters', () async {
      final _FakeAnalyticsSink sink = _FakeAnalyticsSink();
      final service = AiseeAnalyticsService(
        sink: sink,
        onceStore: _MemoryOnceStore(),
      );

      await service.track(
        AiseeAnalyticsEvent.roleSelected,
        parameters: <String, Object?>{
          'role': 'family',
          'has_family_link': true,
          'count': 2,
          'ignored': null,
        },
      );

      expect(sink.events, hasLength(1));
      expect(sink.events.single.name, AiseeAnalyticsEvent.roleSelected);
      expect(sink.events.single.parameters, <String, Object>{
        'role': 'family',
        'has_family_link': 'true',
        'count': 2,
      });
    });

    test('tracks once-only activation milestones once', () async {
      final _FakeAnalyticsSink sink = _FakeAnalyticsSink();
      final service = AiseeAnalyticsService(
        sink: sink,
        onceStore: _MemoryOnceStore(),
      );

      await service.trackOnce(AiseeAnalyticsEvent.firstAiSessionStarted);
      await service.trackOnce(AiseeAnalyticsEvent.firstAiSessionStarted);

      expect(sink.events, hasLength(1));
      expect(
        sink.events.single.name,
        AiseeAnalyticsEvent.firstAiSessionStarted,
      );
    });

    test(
      'records screen context for crash reports and screen analytics',
      () async {
        final _FakeAnalyticsSink sink = _FakeAnalyticsSink();
        final service = AiseeAnalyticsService(
          sink: sink,
          onceStore: _MemoryOnceStore(),
        );

        await service.trackScreen('family_dashboard');

        expect(sink.screenViews, <String>['family_dashboard']);
        expect(sink.crashKeys['current_screen'], 'family_dashboard');
        expect(sink.crashLogs, <String>['screen:family_dashboard']);
      },
    );

    test('tracks tool call success and failure for rate metrics', () async {
      final _FakeAnalyticsSink sink = _FakeAnalyticsSink();
      final service = AiseeAnalyticsService(
        sink: sink,
        onceStore: _MemoryOnceStore(),
      );

      await service.trackToolCall(
        toolName: 'enable_camera',
        success: true,
        durationMs: 120,
      );
      await service.trackToolCall(
        toolName: 'emergency_alert',
        success: false,
        errorCode: 'rpc_failed',
      );

      expect(sink.events.map((event) => event.name), <String>[
        AiseeAnalyticsEvent.toolCallSucceeded,
        AiseeAnalyticsEvent.toolCallFailed,
      ]);
      expect(sink.events.first.parameters['tool_name'], 'enable_camera');
      expect(sink.events.first.parameters['duration_ms'], 120);
      expect(sink.events.last.parameters['tool_name'], 'emergency_alert');
      expect(sink.events.last.parameters['error_code'], 'rpc_failed');
    });
  });
}

class _TrackedEvent {
  const _TrackedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}

class _FakeAnalyticsSink implements AiseeAnalyticsSink {
  final List<_TrackedEvent> events = <_TrackedEvent>[];
  final List<String> screenViews = <String>[];
  final Map<String, Object> crashKeys = <String, Object>{};
  final List<String> crashLogs = <String>[];

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {
    events.add(_TrackedEvent(name, parameters));
  }

  @override
  Future<void> logCrashMessage(String message) async {
    crashLogs.add(message);
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {}

  @override
  Future<void> setCrashKey(String key, Object value) async {
    crashKeys[key] = value;
  }

  @override
  Future<void> setScreenName(String screenName) async {
    screenViews.add(screenName);
  }

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}
}

class _MemoryOnceStore implements AiseeAnalyticsOnceStore {
  final Set<String> _seen = <String>{};

  @override
  Future<bool> hasTracked(String key) async => _seen.contains(key);

  @override
  Future<void> markTracked(String key) async {
    _seen.add(key);
  }
}
