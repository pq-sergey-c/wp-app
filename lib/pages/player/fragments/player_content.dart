import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wp_player/components/controls/external_link_box.dart';
import 'package:wp_player/pages/player/fragments/buffer_time/buffer_time.dart';
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

class MusicPlayer extends HookConsumerWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    // useMemoized is used here because of onPop event of current page - while [build] is still called - PlayerService is already disconnected
    final sessionInfo = useMemoized(
      () => PlayerService().sessionInformation,
      [],
    );
    final canControlPlayback = useMemoized(
      () => PlayerService().canControlPlayback,
      [],
    );
    final startVolume = useMemoized(() => PlayerService().volume, []);
    final providerControlUri = sessionInfo.providerControlUri;

    // controls
    void onVolumeChange(double volume) => PlayerService().volume = volume;

    const double volumeSliderHeight = 40;
    const double trackInfoCardHeight = 45;
    final double externalLinkMaxHeight = providerControlUri != null ? 120 : 0;
    const double bufferTextHeight = 20;

    final playerControlHeightToExclude =
        volumeSliderHeight +
        trackInfoCardHeight +
        externalLinkMaxHeight +
        bufferTextHeight;

    final double spacing = layout.getClampedHeight(percent: 2.5);

    return Column(
      spacing: spacing,
      children: [
        PlaybackTimer(
          currentTimeListenable: PlayerService().currentPlayTimeListenable,
          totalTimeListenable: PlayerService().playbackDurationListenable,
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
                        constraints.maxHeight - playerControlHeightToExclude;
                    final columnWidth = min(constraints.maxWidth, maxHeight);

                    return Column(
                      spacing: layout.getClampedHeight(percent: 3),
                      children: [
                        SizedBox(
                          height: trackInfoCardHeight,
                          width: columnWidth,
                          child: TrackInfoCard(
                            sessionInfo: sessionInfo,
                            popupManager: popup,
                          ),
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
                                    isPlayingListenable:
                                        PlayerService().isPlayingListenable,
                                    onPlayPausePressed: _togglePlay,
                                    isLocallyControllable: canControlPlayback,
                                    sessionInfo: sessionInfo,
                                    currentPositionListenable:
                                        PlayerService()
                                            .currentPlayTimeListenable,
                                    phaseListenable: PlayerService().phase,
                                    isSessionStartedFunction: _isSessionStarted,
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: volumeSliderHeight,
                                width: columnWidth,
                                child: VolumeSlider(
                                  startVolume: startVolume,
                                  onVolumeChanged: onVolumeChange,
                                ),
                              ),

                              SizedBox(
                                height: bufferTextHeight,
                                width: columnWidth,
                                child: BufferTimeWidget(
                                  bufferTimeListenable:
                                      PlayerService().bufferedTimeListenable,
                                ),
                              ),

                              if (providerControlUri != null &&
                                  !sessionInfo.isReplay) ...[
                                Container(
                                  constraints: BoxConstraints(
                                    maxHeight: externalLinkMaxHeight,
                                  ),
                                  width: columnWidth,
                                  child: ExternalLinkBox(
                                    text: const TextSpan(
                                      text: "Advanced controls in your browser",
                                    ),
                                    externalLink: providerControlUri.replace(
                                      queryParameters: {
                                        ...providerControlUri.queryParameters,
                                        'source': 'app',
                                      },
                                    ),
                                    maxAmountOfLines: 2,
                                    onOverflow: TextOverflow.ellipsis,
                                    launchMode: LaunchMode.externalApplication,
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

  static bool _isSessionStarted(WpPhase phase, Duration currentPosition) {
    const nonStartedPhases = [WpPhase.wpPhaseNone, WpPhase.wpPhasePre];
    return currentPosition > Duration.zero || !nonStartedPhases.contains(phase);
  }

  static void _togglePlay() {
    final bool isOffline = PlayerService().isOffline;
    final bool isSessionStarted = _isSessionStarted(
      PlayerService().phase.value,
      PlayerService().currentPlayTimeListenable?.value ?? Duration.zero,
    );

    if (!isSessionStarted && !isOffline) {
      PlayerService().advanceFromPrelude();
    } else if (PlayerService().isPlayingListenable?.value ?? false) {
      PlayerService().pause();
    } else {
      PlayerService().resume();
    }
  }
}
