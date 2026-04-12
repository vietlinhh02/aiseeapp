import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/agent_state.dart';

enum AssistantAudioState {
  idleListeningWake,
  activatingLiveSession,
  conversationActive,
  conversationGracePeriod,
}

typedef AssistantAudioAsyncAction = Future<void> Function();
typedef AssistantAudioLog = void Function(String message);

class AssistantAudioCoordinator {
  AssistantAudioCoordinator({
    required this.startWakeListening,
    required this.stopWakeListening,
    required this.enableAssistantMic,
    required this.disableAssistantMic,
    required this.switchToAssistantTab,
    this.gracePeriod = const Duration(seconds: 20),
    this.onMicReadyAfterWake,
    AssistantAudioLog? log,
  }) : _log = log ?? _defaultLog;

  final AssistantAudioAsyncAction startWakeListening;
  final AssistantAudioAsyncAction stopWakeListening;
  final AssistantAudioAsyncAction enableAssistantMic;
  final AssistantAudioAsyncAction disableAssistantMic;
  final VoidCallback switchToAssistantTab;
  /// Gọi sau khi bật mic LiveKit xong (wake) — rung / a11y để user biết có thể nói.
  final VoidCallback? onMicReadyAfterWake;
  final Duration gracePeriod;
  final AssistantAudioLog _log;

  Timer? _graceTimer;
  AssistantAudioState _state = AssistantAudioState.idleListeningWake;

  AssistantAudioState get state => _state;

  Future<void> enterIdleWakeMode({String reason = 'manual'}) async {
    _cancelGraceTimer(reason: 'enter-idle:$reason');
    await disableAssistantMic();
    await startWakeListening();
    _setState(
      AssistantAudioState.idleListeningWake,
      'Idle wake ready ($reason)',
    );
  }

  Future<void> onWakeDetected({String phrase = 'wake'}) async {
    switchToAssistantTab();
    if (_state != AssistantAudioState.idleListeningWake) {
      _log('Ignore wake "$phrase" in state=$_state');
      return;
    }

    _cancelGraceTimer(reason: 'wake-detected');
    _setState(
      AssistantAudioState.activatingLiveSession,
      'Wake detected "$phrase"',
    );
    try {
      final Stopwatch wakeLatency = Stopwatch()..start();
      _log('WakeLatency t=0ms start (after state=activatingLiveSession)');
      await stopWakeListening();
      _log(
        'WakeLatency t=${wakeLatency.elapsedMilliseconds}ms after stopWakeListening',
      );
      // Sau khi DaVoice nhả AudioRecord: chờ tối thiểu trước khi WebRTC chiếm mic.
      // Android thường cần dài hơn iOS; giảm từ 300ms cố định xuống mức vừa phải.
      final int postWakeDelayMs =
          defaultTargetPlatform == TargetPlatform.android ? 200 : 100;
      await Future<void>.delayed(
        Duration(milliseconds: postWakeDelayMs),
      );
      _log(
        'WakeLatency t=${wakeLatency.elapsedMilliseconds}ms after '
        '${postWakeDelayMs}ms post-wake delay',
      );
      await enableAssistantMic();
      _log(
        'WakeLatency t=${wakeLatency.elapsedMilliseconds}ms after enableAssistantMic',
      );
      final VoidCallback? readyCb = onMicReadyAfterWake;
      if (readyCb != null) {
        try {
          readyCb();
        } catch (e, st) {
          _log('onMicReadyAfterWake failed: $e\n$st');
        }
      }
      _setState(
        AssistantAudioState.conversationActive,
        'Live conversation active',
      );
    } catch (error, stackTrace) {
      _log('Activation failed: $error\n$stackTrace');
      await enterIdleWakeMode(reason: 'activation-failed');
    }
  }

  void onAgentStateChanged(AgentState next) {
    _log('Agent state=$next while audioState=$_state');
    if (next.isFinished) {
      unawaited(enterIdleWakeMode(reason: 'agent-${next.name}'));
      return;
    }

    if (_state == AssistantAudioState.conversationGracePeriod &&
        next.keepsConversationOpen) {
      _cancelGraceTimer(reason: 'activity-resumed');
      _setState(
        AssistantAudioState.conversationActive,
        'Conversation resumed during grace period',
      );
      return;
    }

    if (_state == AssistantAudioState.conversationActive &&
        next.startsGracePeriod) {
      _startGracePeriod();
    }
  }

  Future<void> onAppPaused() async {
    _cancelGraceTimer(reason: 'app-paused');
    final bool wasIdleWake = _state == AssistantAudioState.idleListeningWake;
    await disableAssistantMic();
    if (!wasIdleWake) {
      await startWakeListening();
    }
    _setState(
      AssistantAudioState.idleListeningWake,
      'App paused; wake retained for background',
    );
  }

  Future<void> onAppResumed({required bool liveKitConnected}) async {
    if (!liveKitConnected) {
      _log('Resume skipped: LiveKit not connected');
      return;
    }

    if (_state == AssistantAudioState.idleListeningWake) {
      _log('Resume skipped: wake already active');
      return;
    }

    await enterIdleWakeMode(reason: 'app-resumed');
  }

  void dispose() {
    _cancelGraceTimer(reason: 'dispose');
  }

  void _startGracePeriod() {
    final String graceLabel = gracePeriod.inMilliseconds >= 1000
        ? '${gracePeriod.inSeconds}s'
        : '${gracePeriod.inMilliseconds}ms';
    _cancelGraceTimer(reason: 'restart-grace');
    _setState(
      AssistantAudioState.conversationGracePeriod,
      'Grace period started for $graceLabel',
    );
    _graceTimer = Timer(gracePeriod, () {
      unawaited(enterIdleWakeMode(reason: 'grace-expired'));
    });
  }

  void _cancelGraceTimer({required String reason}) {
    if (_graceTimer == null) {
      return;
    }

    _graceTimer?.cancel();
    _graceTimer = null;
    _log('Grace timer cancelled ($reason)');
  }

  void _setState(AssistantAudioState next, String message) {
    final AssistantAudioState previous = _state;
    _state = next;
    _log('State $previous -> $next | $message');
  }

  static void _defaultLog(String message) {
    debugPrint('[AiSee:WakeFlow] $message');
  }
}
