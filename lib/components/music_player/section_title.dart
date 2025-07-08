import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class SectionTitle extends ConsumerWidget {
  final String title;

  const SectionTitle({required this.title, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return Text(
      title,
      style: TextStyle(
        fontSize: layout.getTextSize(TextSizes.xl2),
        fontVariations: [FontVariationWeight.w700()],
        color: themeMode.themeConfig.title,
      ),
      textAlign: TextAlign.center,
    );
  }
}
