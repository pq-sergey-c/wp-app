import 'package:flutter/material.dart';
import 'package:wp_player/styles/theme_config/theme_config.dart';

@immutable
class ThemeModeState {
  const ThemeModeState._internal(this.mode)
    : themeConfig = mode == ThemeMode.light ? ThemeConfig.lightConfig : ThemeConfig.darkConfig;

  static const light = ThemeModeState._internal(ThemeMode.light);
  static const dark = ThemeModeState._internal(ThemeMode.dark);

  final ThemeMode mode;
  final ThemeConfig themeConfig;

  // ----------------------------------------------

  bool get isDark => mode == ThemeMode.dark;
  bool get isLight => mode == ThemeMode.light;

  // ----------------------------------------------

  A getByMode<A>({required A dark, required A light}) {
    return isLight ? light : dark;
  }

  Color getColorByMode({required Color dark, required Color light}) {
    return getByMode(dark: dark, light: light);
  }
}
