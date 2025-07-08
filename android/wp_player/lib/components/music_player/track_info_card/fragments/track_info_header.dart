import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class TrackInfoHeader extends HookConsumerWidget {
  final bool isExpanded;
  final VoidCallback onTap;
  final String sessionType;

  const TrackInfoHeader({required this.isExpanded, required this.onTap, required this.sessionType, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: themeMode.themeConfig.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            spacing: 12,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.circle, color: AppColors.greenSoft, size: 14),

              Expanded(
                child: Text(
                  sessionType,
                  style: TextStyle(
                    color: themeMode.themeConfig.onPrimary,
                    fontSize: layout.getTextSize(TextSizes.normal),
                    fontVariations: [FontVariationWeight.w700()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: themeMode.themeConfig.onPrimary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
