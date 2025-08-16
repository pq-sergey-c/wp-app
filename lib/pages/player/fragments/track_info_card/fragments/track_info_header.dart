import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class TrackInfoHeader extends HookConsumerWidget {
  final VoidCallback onInfoTap;
  final String sessionType;

  const TrackInfoHeader({required this.onInfoTap, required this.sessionType, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return Container(
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
              textAlign: TextAlign.center,
            ),
          ),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onInfoTap,
              child: SvgPicture.asset(
                'assets/images/info.svg',
                height: 24,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(themeMode.themeConfig.onPrimary, BlendMode.srcIn),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
