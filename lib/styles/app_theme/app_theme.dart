import 'package:flutter/material.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/styles/theme_config/theme_config.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class AppTheme {
  static final ThemeData light = _buildTheme(ThemeConfig.lightConfig);
  static final ThemeData dark = _buildTheme(ThemeConfig.darkConfig);
  static const double baseFontSize = 16; // TODO: maybe move to theme_config

  // ----------------------------------------------------------

  static ThemeData _buildTheme(ThemeConfig config) {
    return ThemeData(
      fontFamily: config.fontFamily,
      brightness: config.brightness,
      scaffoldBackgroundColor: config.background,
      primaryColor: config.primary,
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: config.primary,
        onPrimary: config.onPrimary,
        secondary: config.secondary,
        onSecondary: config.onSecondary,
        error: AppColors.red,
        onError: AppColors.white,
        surfaceTint: config.background.withAlpha(25), // ≈ 10% opacity
        surface: config.surface,
        onSurface: config.text,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: config.title,
          fontSize: _themeFontSize,
          fontVariations: [FontVariationWeight.w700()],
        ),
      ),
      iconTheme: IconThemeData(color: config.primary, size: _themeFontSize),
    );
  }

  static final double _themeFontSize = TextSizes.xl2.fontSize(baseFontSize);
}
