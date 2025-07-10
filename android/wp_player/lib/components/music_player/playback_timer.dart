import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class PlaybackTimer extends ConsumerWidget {
  final String currentTime;
  final String totalTime;

  const PlaybackTimer({required this.currentTime, required this.totalTime, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final isLongTime = currentTime.length > 5 || totalTime.length > 5; // mm:ss or hh:mm:ss

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
                (item: isLongTime ? TextSizes.sm : TextSizes.normal, maxWidth: 425),
              ], fallback: TextSizes.normal),
            ),
            fontVariations: [FontVariationWeight.w700()],
          ),
        ),
      ),
    );
  }
}
