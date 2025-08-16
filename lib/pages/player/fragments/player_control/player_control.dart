import 'package:flutter/material.dart';
import 'package:wp_player/pages/player/fragments/generated_player_card_for_session/generated_player_card_for_session.dart';
import 'package:wp_player/pages/player/fragments/player_control/fragments/player_play_stop_button.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';

class PlayerControl extends StatelessWidget {
  final bool isPlaying;
  final bool isLocallyControllable;
  final VoidCallback onPlayPausePressed;
  final SessionInfo sessionInfo;

  const PlayerControl({
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.isLocallyControllable,
    required this.sessionInfo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GeneratedPlayerCardForSession(sessionInfo: sessionInfo),
        ),
        ...(isLocallyControllable
            ? [PlayerPlayStopButton(onPlayPausePressed: onPlayPausePressed, isPlaying: isPlaying)]
            : []),
      ],
    );
  }
}
