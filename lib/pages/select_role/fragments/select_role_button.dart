import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class SelectRoleButton extends HookConsumerWidget {
  SelectRoleButton({required this.imagePath, required this.label, required this.goToOnClickRoute, super.key});

  final String imagePath;
  final String label;
  final String goToOnClickRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final isHovering = useState<bool>(false);

    return SizedBox(
      height: layout.selectByScreenType(
        mobile: layout.getClampedHeight(percent: 18, min: 700 * 0.18),
        desktop: layout.getClampedHeight(percent: 35, min: 700 * 0.35),
        orElse: layout.getClampedHeight(percent: 25, min: 700 * 0.25),
      ),
      width: layout.selectByScreenType(
        mobile: layout.getClampedWidth(percent: 100),
        tablet: layout.getClampedWidth(percent: 35),
        desktop: layout.getClampedWidth(percent: 25, min: 300),
      ),
      child: MouseRegion(
        onEnter: (_) => isHovering.value = true,
        onExit: (_) => isHovering.value = false,
        child: AnimatedScale(
          scale: isHovering.value ? 1.01 : 1,
          duration: const Duration(milliseconds: 150),
          child: OutlinedButton(
            style: ButtonStyle(
              shape: WidgetStateProperty.all<OutlinedBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              padding: WidgetStateProperty.all<EdgeInsetsGeometry>(EdgeInsetsGeometry.zero),
              side: WidgetStateProperty.all<BorderSide>(
                BorderSide(
                  color: themeMode.getColorByMode(dark: AppColors.indigoDusk, light: AppColors.blueIron),
                  width: 2,
                ),
              ),
            ),

            onPressed: () => unawaited(context.push(goToOnClickRoute)),
            child: Container(
              constraints: const BoxConstraints.expand(),
              decoration: BoxDecoration(
                color: themeMode.getColorByMode(dark: AppColors.transparent, light: AppColors.white),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.symmetric(
                vertical: layout.selectByScreenType(orElse: 16, desktop: 32),
                horizontal: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Expanded(
                    child: ColorFiltered(
                      colorFilter: themeMode.getByMode(
                        dark: _plusLighterToDarkBackgroundMatrix,
                        light: _identityColorFilterMatrix,
                      ),
                      child: Image.asset(imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: layout.getTextSize(TextSizes.xl),
                      fontVariations: [FontVariationWeight.w700()],
                      color: themeMode.getColorByMode(dark: AppColors.white, light: AppColors.blueIron),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Applies effect like css plus-lighter for color, that is used in evaluation of this matrix, as background
  final _plusLighterToDarkBackgroundMatrix = ColorFilter.matrix([
    1.0, 0.0, 0.0, 0.0, AppColors.blueIron.r * 255, //
    0.0, 1.0, 0.0, 0.0, AppColors.blueIron.g * 255,
    0.0, 0.0, 1.0, 0.0, AppColors.blueIron.b * 255,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);

  // does nothing
  static const _identityColorFilterMatrix = ColorFilter.matrix([
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}
