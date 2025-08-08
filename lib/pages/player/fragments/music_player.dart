import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/music_player/playback_timer.dart';
import 'package:wp_player/components/music_player/player_control/player_control.dart';
import 'package:wp_player/components/music_player/section_title.dart';
import 'package:wp_player/components/music_player/track_info_card/track_info_card.dart';
import 'package:wp_player/components/music_player/volume_slider.dart';
import 'package:wp_player/components/music_player/wavepaths_logo.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/utils/data_format/to_string_formatted/format_duration_minutes_seconds.dart';

class MusicPlayerPage extends HookConsumerWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // cause on pop of page - while [build] is still called - PlayerService is already disconnected
    final SessionInfo sessionInfo = useMemoized(() => PlayerService().sessionInformation, []);
    final canControlPlayback = useMemoized(() => PlayerService().canControlPlayback, []);

    final layout = ref.watch(responsiveLayoutProvider);

    final isExpanded = useState(false);
    final volume = useMemoized(() => PlayerService().volume, []);

    // listen to notifiers
    final Duration? duration = useListenable(PlayerService().playbackDurationListenable)?.value;
    final Duration? currentPosition = useListenable(PlayerService().currentPlayTimeListenable)?.value;
    final bool isPlaying = useListenable(PlayerService().isPlayingListenable)?.value ?? false;

    final bool isTimeWithHours = duration != null && duration.inHours > 0;

    // controls
    void onVolumeChange(double volume) => PlayerService().volume = volume;

    void togglePlay() {
      if (isPlaying) {
        PlayerService().pause();
      } else {
        PlayerService().resume();
      }
    }

    return Center(
      child: SizedBox(
        width: layout.getClampedWidth(percent: 23.5, min: 300),
        child: Column(
          children: [
            PlaybackTimer(
              currentTime: formatDuration(currentPosition, withHours: isTimeWithHours),
              totalTime: formatDuration(duration, withHours: isTimeWithHours),
            ),

            SizedBox(height: layout.getClampedHeight(percent: 3)),

            SectionTitle(title: sessionInfo.title),

            SizedBox(height: layout.getClampedHeight(percent: 3)),

            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.getClampedHeight(percent: 42, min: 300)),
              child: TrackInfoCard(
                sessionInfo: sessionInfo,
                isExpanded: isExpanded.value,
                onExpandToggle: () => isExpanded.value = !isExpanded.value,
              ),
            ),

            SizedBox(height: layout.getClampedHeight(percent: 3)),

            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: layout.getClampedHeight(percent: 42, min: 300)),
              child: PlayerControl(
                isPlaying: isPlaying,
                onPlayPausePressed: togglePlay,
                isLocallyControllable: canControlPlayback,
                sessionInfo: sessionInfo,
              ),
            ),

            SizedBox(height: layout.getClampedHeight(percent: 3)),

            SizedBox(
              width: layout.getClampedHeight(percent: 42, min: 300),
              child: VolumeSlider(startVolume: volume, onVolumeChanged: onVolumeChange),
            ),

            SizedBox(height: layout.getClampedHeight(percent: 6.5)),

            const WavePathsLogo(),

            SizedBox(height: layout.getClampedHeight(percent: 1)),
          ],
        ),
      ),
    );
  }
}
