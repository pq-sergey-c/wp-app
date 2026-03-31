import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/utils/data_format/to_string_formatted/format_duration_minutes_seconds.dart';

class BufferTimeWidget extends HookConsumerWidget {
  final ValueListenable<Duration?>? bufferTimeListenable;

  const BufferTimeWidget({required this.bufferTimeListenable, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final durationListenable = useListenable(bufferTimeListenable);
    final duration = durationListenable?.value ?? Duration.zero;
    final phase = useValueListenable(PlayerService().phase);
    final hasAudioStarted = useValueListenable(
      PlayerService().hasAudioStartedListenable,
    );

    final String displayText;
    switch (phase) {
      case WpPhase.wpPhasePre:
        displayText = 'Prelude';
      case WpPhase.wpPhasePost:
        displayText = 'Postlude';
      case WpPhase.wpPhaseSession:
        if (hasAudioStarted) {
          displayText =
              'Loaded session: ${formatDuration(duration, withHours: duration.inHours > 0)}';
        } else {
          displayText = 'Loading audio...';
        }
      default:
        displayText = '';
    }

    return Text(
      displayText,
      style: TextStyle(
        fontSize: layout.getTextSize(TextSizes.normal),
        fontVariations: [FontVariationWeight.w600()],
      ),
      textAlign: TextAlign.center,
    );
  }
}
