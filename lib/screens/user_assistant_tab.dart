import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/agent_state.dart';
import '../theme/style_tokens.dart';
import '../widgets/assistant_orb.dart';

/// Tab Trợ lý — mặc định trong [UserHomeScreen], không phải route riêng.
class UserAssistantTab extends StatelessWidget {
  const UserAssistantTab({
    super.key,
    required this.aiseeLoading,
    required this.aiseeError,
    required this.assistantConnecting,
    required this.assistantError,
    required this.assistantConnected,
    this.nowPlayingTitle,
    this.assistantWaveEnergy,
    this.agentState,
    this.assistantCameraPreview,
    required this.onRetryAssistant,
  });

  final bool aiseeLoading;
  final String? aiseeError;
  final bool assistantConnecting;
  final String? assistantError;
  final bool assistantConnected;
  final String? nowPlayingTitle;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final Widget? assistantCameraPreview;
  final Future<void> Function() onRetryAssistant;

  static List<Shadow> _textShadowsOnVideo() {
    return const <Shadow>[
      Shadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0xCC000000)),
      Shadow(offset: Offset(0, 0), blurRadius: 12, color: Color(0x99000000)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: _semanticsLabel(l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (aiseeLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
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
          else if (assistantConnecting)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (assistantError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      assistantError!,
                      textAlign: TextAlign.center,
                      style: StyleTokens.bodySmall().copyWith(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        unawaited(onRetryAssistant());
                      },
                      child: Text(
                        l.assistantTabRetry,
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
              child: assistantConnected && assistantCameraPreview != null
                  ? _AssistantLiveBody(
                      assistantConnected: assistantConnected,
                      cameraPreview: assistantCameraPreview!,
                      assistantWaveEnergy: assistantWaveEnergy,
                      agentState: agentState,
                      nowPlayingTitle: nowPlayingTitle,
                      textShadowsOnVideo: _textShadowsOnVideo,
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: _AssistantContentColumn(
                          assistantConnected: assistantConnected,
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

  String _semanticsLabel(AppLocalizations l) {
    if (aiseeLoading) return l.assistantTabSemanticsLoading;
    if (aiseeError != null) return l.assistantTabSemanticsError;
    if (assistantConnecting) return l.assistantTabSemanticsConnecting;
    if (assistantError != null) return l.assistantTabSemanticsConnectError;
    if (assistantConnected) return l.assistantTabSemanticsConnected;
    return l.assistantTabSemanticsDefault;
  }
}

class _AssistantLiveBody extends StatelessWidget {
  const _AssistantLiveBody({
    required this.assistantConnected,
    required this.cameraPreview,
    required this.assistantWaveEnergy,
    required this.agentState,
    required this.nowPlayingTitle,
    required this.textShadowsOnVideo,
  });

  final bool assistantConnected;
  final Widget cameraPreview;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final String? nowPlayingTitle;
  final List<Shadow> Function() textShadowsOnVideo;

  @override
  Widget build(BuildContext context) {
    final bool showFullBleed = assistantConnected;

    if (!showFullBleed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: _AssistantContentColumn(
            assistantConnected: assistantConnected,
            onVideo: false,
            textShadowsOnVideo: textShadowsOnVideo,
            assistantWaveEnergy: assistantWaveEnergy,
            agentState: agentState,
            nowPlayingTitle: nowPlayingTitle,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Semantics(
            label: AppLocalizations.of(context).assistantTabCameraPreviewLabel,
            child: cameraPreview,
          ),
        ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _AssistantContentColumn(
                assistantConnected: assistantConnected,
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
    required this.assistantConnected,
    required this.onVideo,
    required this.textShadowsOnVideo,
    required this.assistantWaveEnergy,
    required this.agentState,
    required this.nowPlayingTitle,
  });

  final bool assistantConnected;
  final bool onVideo;
  final List<Shadow> Function() textShadowsOnVideo;
  final ValueListenable<double>? assistantWaveEnergy;
  final ValueListenable<AgentState>? agentState;
  final String? nowPlayingTitle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
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
                state.displayText(AppLocalizations.of(context)),
                textAlign: TextAlign.center,
                style: base,
              );
            },
          )
        else
          Text(
            assistantConnected
                ? l.assistantTabConnected
                : l.assistantTabConnecting,
            textAlign: TextAlign.center,
            style: base,
          ),
        if (assistantConnected &&
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
            l.assistantTabNowPlaying(nowPlayingTitle!.trim()),
            textAlign: TextAlign.center,
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 14,
              height: 1.35,
              color: onVideo
                  ? const Color(0xFFFFFFFF)
                  : StyleTokens.textSecondary,
              shadows: onVideo ? textShadowsOnVideo() : null,
            ),
          ),
        ],
      ],
    );
  }
}
