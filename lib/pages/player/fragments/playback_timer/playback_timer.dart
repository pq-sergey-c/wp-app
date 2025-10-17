import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/utils/data_format/to_string_formatted/format_duration_minutes_seconds.dart';

class PlaybackTimer extends HookConsumerWidget {
  final ValueListenable<Duration?>? currentTimeListenable;
  final ValueListenable<Duration?>? totalTimeListenable;

  const PlaybackTimer({required this.currentTimeListenable, required this.totalTimeListenable, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final totalTimeDuration = useListenable(totalTimeListenable)?.value ?? Duration.zero;
    final currentTimeDuration = useListenable(currentTimeListenable)?.value ?? Duration.zero;

    final withHours = totalTimeDuration.inHours > 0;

    final totalTime = formatDuration(totalTimeDuration, withHours: withHours);
    final currentTime = formatDuration(currentTimeDuration, withHours: withHours);

    return Container(
      height: layout.getClampedHeight(percent: 7, min: 50),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: themeMode.themeConfig.primary, borderRadius: BorderRadius.circular(80)),
      child: Align(
        widthFactor: 1,
        alignment: Alignment.center,
        child: Text(
          "$currentTime / $totalTime",
          style: TextStyle(
            color: themeMode.themeConfig.onPrimary,
            fontSize: layout.getTextSize(
              layout.widthBreakpoints([
                (item: withHours ? TextSizes.sm : TextSizes.normal, maxWidth: 425),
              ], fallback: TextSizes.normal),
            ),
            fontVariations: [FontVariationWeight.w700()],
          ),
        ),
      ),
    );
  }
}
