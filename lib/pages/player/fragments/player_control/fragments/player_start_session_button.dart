import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class PlayerStartSessionButton extends ConsumerWidget {
  const PlayerStartSessionButton({required this.onPlayPausePressed, super.key});

  final VoidCallback onPlayPausePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layouter = ref.watch(responsiveLayoutProvider);

    return Center(
      child: InkWell(
        onTap: onPlayPausePressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(color: themeMode.themeConfig.primary, borderRadius: BorderRadius.circular(25)),
          child: Text(
            'Start Session',
            style: TextStyle(
              color: themeMode.themeConfig.onPrimary,
              fontSize: layouter.getTextSize(TextSizes.lg),
              fontVariations: [FontVariationWeight.w600()],
            ),
          ),
        ),
      ),
    );
  }
}
