import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/providers/theme_mode/types/theme_mode.state.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

enum ButtonVariation { filled, outlined }

class Button extends ConsumerWidget {
  const Button({
    required this.onClicked,
    required this.text,
    this.height,
    this.width,
    this.textStyle,
    this.buttonStyle,
    this.buttonVariation = ButtonVariation.filled,
    super.key,
  });

  final void Function() onClicked;
  final String text;
  final double? width;
  final double? height;
  final TextStyle? textStyle;
  final ButtonStyle? buttonStyle;
  final ButtonVariation buttonVariation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    return SizedBox(
      width: width ?? layout.getClampedWidth(percent: 90, max: 300),
      height: height ?? layout.getClampedHeight(percent: 10, max: 70, min: 60),
      child: ElevatedButton(
        style: buttonStyle ?? _getButtonStyleByVariation(themeMode),
        onPressed: onClicked,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style:
              textStyle ??
              TextStyle(
                fontSize: layout.getTextSize(TextSizes.lg),
                fontFamily: themeMode.themeConfig.fontFamily,
                color: themeMode.themeConfig.onPrimary,
                fontVariations: [FontVariationWeight.w700()],
              ),
        ),
      ),
    );
  }

  dynamic _getButtonStyleByVariation(ThemeModeState themeMode) {
    return switch (buttonVariation) {
      ButtonVariation.filled => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(themeMode.themeConfig.primary),
      ),
      ButtonVariation.outlined => ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(themeMode.themeConfig.background),
        side: WidgetStateProperty.all<BorderSide>(
          BorderSide(
            color: themeMode.getColorByMode(
              dark: themeMode.themeConfig.onPrimary,
              light: themeMode.themeConfig.primary,
            ),
          ),
        ),
        overlayColor: WidgetStateProperty.all<Color>(
          themeMode.getColorByMode(dark: AppColors.blueIronLight, light: AppColors.greyFog),
        ),
      ),
    };
  }
}
