import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:livekit_client/livekit_client.dart' hide AgentState;

import '../models/agent_state.dart';
import '../theme/style_tokens.dart';
import '../widgets/assistant_local_camera_preview.dart';
import '../widgets/assistant_orb.dart';

/// Tab Trợ lý — mặc định trong [UserHomeScreen], không phải route riêng.
class UserAssistantTab extends StatelessWidget {
  const UserAssistantTab({
    super.key,
    required this.aiseeLoading,
    required this.aiseeError,
    required this.liveKitConnecting,
    required this.liveKitError,
    required this.liveKitConnected,
    this.nowPlayingTitle,
    this.assistantWaveEnergy,
    this.agentState,
    this.localCameraPreviewTrack,
    required this.onRetryLiveKit,
  });

  final bool aiseeLoading;
  final String? aiseeError;
  final bool liveKitConnecting;
  final String? liveKitError;
  final bool liveKitConnected;
  final String? nowPlayingTitle;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final ValueListenable<LocalVideoTrack?>? localCameraPreviewTrack;
  final Future<void> Function() onRetryLiveKit;

  static List<Shadow> _textShadowsOnVideo() {
    return const <Shadow>[
      Shadow(
        offset: Offset(0, 1),
        blurRadius: 6,
        color: Color(0xCC000000),
      ),
      Shadow(
        offset: Offset(0, 0),
        blurRadius: 12,
        color: Color(0x99000000),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aiseeLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (aiseeError != null)
            Expanded(
              child: Center(
                child: Text(
                  aiseeError!,
                  textAlign: TextAlign.center,
                  style: StyleTokens.bodySmall().copyWith(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            )
          else if (liveKitConnecting)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (liveKitError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      liveKitError!,
                      textAlign: TextAlign.center,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        unawaited(onRetryLiveKit());
                      },
                      child: Text(
                        'Thử lại',
                        style: StyleTokens.bodySmall().copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: StyleTokens.navSelectedPill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: liveKitConnected && localCameraPreviewTrack != null
                  ? ValueListenableBuilder<LocalVideoTrack?>(
                      valueListenable: localCameraPreviewTrack!,
                      builder: (BuildContext context, LocalVideoTrack? track, _) {
                        return _AssistantLiveBody(
                          liveKitConnected: liveKitConnected,
                          localVideoTrack: track,
                          assistantWaveEnergy: assistantWaveEnergy,
                          agentState: agentState,
                          nowPlayingTitle: nowPlayingTitle,
                          textShadowsOnVideo: _textShadowsOnVideo,
                        );
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: _AssistantContentColumn(
                          liveKitConnected: liveKitConnected,
                          onVideo: false,
                          textShadowsOnVideo: _textShadowsOnVideo,
                          assistantWaveEnergy: assistantWaveEnergy,
                          agentState: agentState,
                          nowPlayingTitle: nowPlayingTitle,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  String get _semanticsLabel {
    if (aiseeLoading) return 'Trang Trợ lý AiSee. Đang tải hồ sơ.';
    if (aiseeError != null) return 'Trang Trợ lý AiSee. Có lỗi hồ sơ.';
    if (liveKitConnecting) return 'Trang Trợ lý AiSee. Đang kết nối trợ lý.';
    if (liveKitError != null) {
      return 'Trang Trợ lý AiSee. Lỗi kết nối. Chạm Thử lại để thử lại.';
    }
    if (liveKitConnected) return 'Trang Trợ lý AiSee. Đã kết nối trợ lý giọng nói.';
    return 'Trang Trợ lý AiSee.';
  }
}

class _AssistantLiveBody extends StatelessWidget {
  const _AssistantLiveBody({
    required this.liveKitConnected,
    required this.localVideoTrack,
    required this.assistantWaveEnergy,
    required this.agentState,
    required this.nowPlayingTitle,
    required this.textShadowsOnVideo,
  });

  final bool liveKitConnected;
  final LocalVideoTrack? localVideoTrack;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final String? nowPlayingTitle;
  final List<Shadow> Function() textShadowsOnVideo;

  @override
  Widget build(BuildContext context) {
    final bool showFullBleed =
        liveKitConnected && localVideoTrack != null;

    if (!showFullBleed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: _AssistantContentColumn(
            liveKitConnected: liveKitConnected,
            onVideo: false,
            textShadowsOnVideo: textShadowsOnVideo,
            assistantWaveEnergy: assistantWaveEnergy,
            agentState: agentState,
            nowPlayingTitle: nowPlayingTitle,
          ),
        ),
      );
    }

    final LocalVideoTrack track = localVideoTrack!;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Semantics(
            label: 'Xem trước camera của bạn, toàn màn hình',
            child: AssistantLiveCameraBackdrop(track: track),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _AssistantContentColumn(
                liveKitConnected: liveKitConnected,
                onVideo: true,
                textShadowsOnVideo: textShadowsOnVideo,
                assistantWaveEnergy: assistantWaveEnergy,
                agentState: agentState,
                nowPlayingTitle: nowPlayingTitle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantContentColumn extends StatelessWidget {
  const _AssistantContentColumn({
    required this.liveKitConnected,
    required this.onVideo,
    required this.textShadowsOnVideo,
    required this.assistantWaveEnergy,
    required this.agentState,
    required this.nowPlayingTitle,
  });

  final bool liveKitConnected;
  final bool onVideo;
  final List<Shadow> Function() textShadowsOnVideo;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final String? nowPlayingTitle;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = StyleTokens.bodySmall().copyWith(
      fontSize: 16,
      height: 1.4,
      color: onVideo ? const Color(0xFFFFFFFF) : StyleTokens.textPrimary,
      shadows: onVideo ? textShadowsOnVideo() : null,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (agentState != null)
          ValueListenableBuilder<AgentState>(
            valueListenable: agentState!,
            builder: (BuildContext context, AgentState state, _) {
              return Text(
                state.displayTextVi,
                textAlign: TextAlign.center,
                style: base,
              );
            },
          )
        else
          Text(
            liveKitConnected
                ? 'Đã kết nối trợ lý giọng nói.'
                : 'Đang chờ kết nối…',
            textAlign: TextAlign.center,
            style: base,
          ),
        if (liveKitConnected &&
            assistantWaveEnergy != null &&
            agentState != null) ...[
          const SizedBox(height: 20),
          AssistantOrb(
            agentState: agentState!,
            voiceEnergy: assistantWaveEnergy!,
          ),
        ],
        if (nowPlayingTitle != null && nowPlayingTitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Đang phát: ${nowPlayingTitle!.trim()}',
            textAlign: TextAlign.center,
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 14,
              height: 1.35,
              color: onVideo ? const Color(0xFFFFFFFF) : StyleTokens.textSecondary,
              shadows: onVideo ? textShadowsOnVideo() : null,
            ),
          ),
        ],
      ],
    );
  }
}

