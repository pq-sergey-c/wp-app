import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class PlayerPlayStopButton extends ConsumerWidget {
  final VoidCallback onPlayPausePressed;
  final bool isPlaying;

  const PlayerPlayStopButton({required this.onPlayPausePressed, required this.isPlaying, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Center(
      child: InkWell(
        onTap: onPlayPausePressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double superWidgetWidth = constraints.maxWidth;
            final double width = (superWidgetWidth * 0.4).clamp(50, 140);

            return Container(
              width: width,
              height: width,
              decoration: BoxDecoration(
                color: themeMode.getColorByMode(dark: AppColors.white.withAlpha(185), light: AppColors.blueIron),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: width / 2, // Icon size
                color: themeMode.getColorByMode(dark: AppColors.blueIron, light: AppColors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
