import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wp_player/pages/player/fragments/generated_player_card_for_session/generated_player_card_for_session.dart';
import 'package:wp_player/pages/player/fragments/player_control/fragments/player_play_stop_button.dart';
import 'package:wp_player/pages/player/fragments/player_control/fragments/player_start_session_button.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/types/session/session_render_type/session_render_type.dart';

class PlayerControl extends HookWidget {
  final ValueListenable<bool>? isPlayingListenable;
  final bool isLocallyControllable;
  final VoidCallback onPlayPausePressed;
  final SessionInfo sessionInfo;
  final ValueListenable<WpPhase> phaseListenable;
  final ValueListenable<Duration?>? currentPositionListenable;
  final bool Function(WpPhase phase, Duration currentPosition) isSessionStartedFunction;

  const PlayerControl({
    required this.isPlayingListenable,
    required this.onPlayPausePressed,
    required this.isLocallyControllable,
    required this.sessionInfo,
    required this.phaseListenable,
    required this.currentPositionListenable,
    required this.isSessionStartedFunction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = useListenable(isPlayingListenable)?.value ?? false;
    final phase = useListenable(phaseListenable).value;
    final currentPosition = useListenable(currentPositionListenable)?.value ?? Duration.zero;

    final isSessionStarted = isSessionStartedFunction(phase, currentPosition);
    final showStartSessionButton = !isSessionStarted && sessionInfo.sessionType == SessionRenderType.predictiveComposed;

    final control = _buildControlButton(showStartSessionButton, isPlaying);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GeneratedPlayerCardForSession(sessionInfo: sessionInfo),
        ),
        if (control != null) control,
      ],
    );
  }

  Widget? _buildControlButton(bool showStartSessionButton, bool isPlaying) {
    if (!isLocallyControllable) return null;

    if (showStartSessionButton) {
      return PlayerStartSessionButton(onPlayPausePressed: onPlayPausePressed);
    } else {
      return PlayerPlayStopButton(onPlayPausePressed: onPlayPausePressed, isPlaying: isPlaying);
    }
  }
}
