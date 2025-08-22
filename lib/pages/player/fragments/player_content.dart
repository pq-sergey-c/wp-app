import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/controls/external_link_box.dart';
import 'package:wp_player/pages/player/fragments/playback_timer/playback_timer.dart';
import 'package:wp_player/pages/player/fragments/player_control/player_control.dart';
import 'package:wp_player/pages/player/fragments/title_and_logo/section_title.dart';
import 'package:wp_player/pages/player/fragments/title_and_logo/wavepaths_logo.dart';
import 'package:wp_player/pages/player/fragments/track_info_card/track_info_card.dart';
import 'package:wp_player/pages/player/fragments/volume_slider/volume_slider.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/utils/data_format/to_string_formatted/format_duration_minutes_seconds.dart';

class MusicPlayer extends HookConsumerWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    // useMemoized here because on pop of page - while [build] is still called - PlayerService is already disconnected
    final sessionInfo = useMemoized(() => PlayerService().sessionInformation, []);
    final canControlPlayback = useMemoized(() => PlayerService().canControlPlayback, []);
    final startVolume = useMemoized(() => PlayerService().volume, []);
    final providerControlUri = sessionInfo.providerControlUri;

    // listen to notifiers
    final Duration? duration = useListenable(PlayerService().playbackDurationListenable)?.value;
    final Duration? currentPosition = useListenable(PlayerService().currentPlayTimeListenable)?.value;
    final bool isPlaying = useListenable(PlayerService().isPlayingListenable)?.value ?? false;
    final WpPhase playerPhase = useListenable(PlayerService().phase).value; // CONTINUE: 1 (here is getter)
    final bool isSessionStarted = (playerPhase != WpPhase.wpPhaseNone && playerPhase != WpPhase.wpPhasePre) || currentPosition != Duration.zero;
    final bool isOffline = PlayerService().isOffline;
    final bool isTimeWithHours = duration != null && duration.inHours > 0;

    // controls
    void onVolumeChange(double volume) => PlayerService().volume = volume;
    void togglePlay() {
      if (!isSessionStarted && !isOffline) {
        PlayerService().advanceFromPrelude();
      } else if (isPlaying) {
        PlayerService().pause();
      } else {
        PlayerService().resume();
      }
    }

    const double volumeSliderHeight = 60;
    const double trackInfoCardHeight = 65;
    final double externalLinkMaxHeight = providerControlUri != null ? 120 : 0;
    final double spacing = layout.getClampedHeight(percent: 3);

    return Column(
      spacing: spacing,
      children: [
        PlaybackTimer(
          currentTime: formatDuration(currentPosition, withHours: isTimeWithHours),
          totalTime: formatDuration(duration, withHours: isTimeWithHours),
        ),

        Flexible(
          child: Column(
            spacing: spacing,
            children: [
              SectionTitle(title: sessionInfo.title),

              Flexible(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight =
                        constraints.maxHeight - volumeSliderHeight - trackInfoCardHeight - externalLinkMaxHeight;
                    final columnWidth = min(constraints.maxWidth, maxHeight);
                    return Column(
                      spacing: layout.getClampedHeight(percent: 3),
                      children: [
                        SizedBox(
                          height: trackInfoCardHeight,
                          width: columnWidth,
                          child: TrackInfoCard(sessionInfo: sessionInfo, popupManager: popup),
                        ),

                        Flexible(
                          child: Column(
                            spacing: layout.getClampedHeight(percent: 1.5),
                            children: [
                              Flexible(
                                child: SizedBox(
                                  width: columnWidth,
                                  height: columnWidth,
                                  child: PlayerControl(
                                    isSessionStarted: isSessionStarted,
                                    isPlaying: isPlaying,
                                    onPlayPausePressed: togglePlay,
                                    isLocallyControllable: canControlPlayback,
                                    sessionInfo: sessionInfo,
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: volumeSliderHeight,
                                width: columnWidth,
                                child: VolumeSlider(startVolume: startVolume, onVolumeChanged: onVolumeChange),
                              ),

                              if (providerControlUri != null) ...[
                                Container(
                                  constraints: BoxConstraints(maxHeight: externalLinkMaxHeight),
                                  width: columnWidth,
                                  child: ExternalLinkBox(
                                    text: const TextSpan(text: "Advanced controls in your browser"),
                                    externalLink: providerControlUri,
                                    maxAmountOfLines: 2,
                                    onOverflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const WavePathsLogo(),
      ],
    );
  }
}
