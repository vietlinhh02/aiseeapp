import 'dart:async';

import 'package:flutter/material.dart';

import '../config/aisee_navigator_key.dart';
import '../models/aisee_call_info.dart';
import '../models/aisee_family_member.dart';
import '../screens/call_screen.dart';

class AiseeAssistantCallLauncher {
  AiseeAssistantCallLauncher._();

  static final AiseeAssistantCallLauncher instance =
      AiseeAssistantCallLauncher._();

  Future<Map<String, Object?>> startCall(Map<String, dynamic> params) async {
    if (CallScreen.openRouteCount > 0) {
      return const <String, Object?>{
        'status': 'busy',
        'message': 'A call is already in progress.',
      };
    }

    final NavigatorState? navigator = aiseeNavigatorKey.currentState;
    if (navigator == null) {
      return const <String, Object?>{
        'status': 'failed',
        'message': 'Call UI is not ready.',
      };
    }

    final String roomName = _stringParam(params, const <String>[
      'room_name',
      'roomName',
    ]);
    final String token = _stringParam(params, const <String>['token']);
    if (roomName.isEmpty || token.isEmpty) {
      return const <String, Object?>{
        'status': 'failed',
        'message': 'Missing room or token for start_call.',
      };
    }

    final String callType = _normalizedCallType(
      _stringParam(params, const <String>['call_type', 'callType']),
    );
    final String contactName = _stringParam(params, const <String>[
      'contact_name',
      'contactName',
    ]);
    final String contactRole = _stringParam(params, const <String>[
      'contact_role',
      'contactRole',
    ]);
    final String contactID = _stringParam(params, const <String>[
      'contact_id',
      'contactId',
    ]);
    final String avatarUrl = _stringParam(params, const <String>[
      'avatar_url',
      'avatarUrl',
    ]);
    final Duration answerTimeout = Duration(
      seconds: _intParam(params, const <String>[
        'answer_timeout_seconds',
        'answerTimeoutSeconds',
      ], fallback: 30),
    );

    final Completer<Map<String, Object?>> result =
        Completer<Map<String, Object?>>();
    final Future<void> routeFuture = navigator.push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CallScreen(
          callInfo: AiseeCallInfo(
            roomName: roomName,
            token: token,
            callType: callType,
            contact: AiseeFamilyMember(
              id: contactID.isNotEmpty ? contactID : roomName,
              email: '',
              displayName: contactName.isNotEmpty
                  ? contactName
                  : 'Người hỗ trợ',
              role: contactRole.isNotEmpty ? contactRole : 'family',
              avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            ),
          ),
          outgoingAnswerTimeout: answerTimeout,
          onAnswered: () {
            // Keep the assistant tool request open while the user is in-call.
            // The final result is reported from onEnded with duration/reason.
          },
          onNoAnswer: () {
            _completeResult(result, <String, Object?>{
              'status': 'no_answer',
              'room_name': roomName,
              'call_type': callType,
              'contact_name': contactName,
              'contact_role': contactRole,
            });
          },
          onStartFailed: (String message) {
            _completeResult(result, <String, Object?>{
              'status': 'failed',
              'message': message,
              'room_name': roomName,
              'call_type': callType,
            });
          },
          onCancelledWhileRinging: () {
            _completeResult(result, <String, Object?>{
              'status': 'cancelled',
              'room_name': roomName,
              'call_type': callType,
            });
          },
          onEnded:
              ({
                required bool answered,
                required Duration duration,
                required bool remoteEnded,
              }) {
                _completeResult(result, <String, Object?>{
                  'status': aiseeAssistantCallEndStatus(
                    answered: answered,
                    remoteEnded: remoteEnded,
                    duration: duration,
                  ),
                  'answered': answered,
                  'remote_ended': remoteEnded,
                  'duration_seconds': duration.inSeconds,
                  'room_name': roomName,
                  'call_type': callType,
                  'contact_name': contactName,
                  'contact_role': contactRole,
                });
              },
        ),
      ),
    );

    unawaited(
      routeFuture.whenComplete(() {
        _completeResult(result, <String, Object?>{
          'status': 'cancelled',
          'room_name': roomName,
          'call_type': callType,
        });
      }),
    );

    return result.future;
  }

  static void _completeResult(
    Completer<Map<String, Object?>> completer,
    Map<String, Object?> value,
  ) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  static String _stringParam(Map<String, dynamic> params, List<String> keys) {
    for (final String key in keys) {
      final Object? value = params[key];
      if (value == null) {
        continue;
      }
      final String text = value is String ? value : value.toString();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  static int _intParam(
    Map<String, dynamic> params,
    List<String> keys, {
    required int fallback,
  }) {
    for (final String key in keys) {
      final Object? value = params[key];
      if (value is int) {
        return value > 0 ? value : fallback;
      }
      if (value is double) {
        return value > 0 ? value.round() : fallback;
      }
      if (value is String) {
        final int? parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  static String _normalizedCallType(String value) {
    return value == 'video' ? 'video' : 'voice';
  }
}
