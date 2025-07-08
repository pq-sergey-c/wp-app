import 'dart:ui';

import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/styles/fonts/fonts.dart';

class ThemeConfig {
  final Brightness brightness;

  final Color background;
  final Color surface;

  final Color primary;
  final Color onPrimary;

  final Color secondary;
  final Color onSecondary;

  final Color title;
  final Color text;
  final Color subtext;

  final Color cardBackground;

  final String fontFamily;

  const ThemeConfig({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.title,
    required this.text,
    required this.subtext,
    required this.cardBackground,
    required this.fontFamily,
  });

  static const lightConfig = ThemeConfig(
    brightness: Brightness.light,
    background: AppColors.beigeLight,
    surface: AppColors.beigeLight,
    primary: AppColors.blueIron,
    onPrimary: AppColors.white,
    secondary: AppColors.indigo,
    onSecondary: AppColors.black,
    title: AppColors.blueIron,
    text: AppColors.blueIron,
    subtext: AppColors.greyAsh,
    cardBackground: AppColors.white,
    fontFamily: Fonts.inter,
  );

  static const darkConfig = ThemeConfig(
    brightness: Brightness.dark,
    background: AppColors.blueIron,
    surface: AppColors.blueIron,
    primary: AppColors.indigoMist,
    onPrimary: AppColors.white,
    secondary: AppColors.blueLight,
    onSecondary: AppColors.white,
    title: AppColors.white,
    text: AppColors.white,
    subtext: AppColors.greyMuted,
    cardBackground: AppColors.indigoDusk,
    fontFamily: Fonts.inter,
  );
}
