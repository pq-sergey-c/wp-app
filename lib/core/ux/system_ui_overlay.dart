import 'package:flutter/services.dart';
import 'package:wp_player/providers/theme_mode/types/theme_mode.state.dart';

SystemUiOverlayStyle systemUiOverlayStyleForTheme(ThemeModeState themeState) {
  final background = themeState.themeConfig.background;
  final iconBrightness = themeState.isDark ? Brightness.light : Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: background,
    statusBarIconBrightness: iconBrightness,
    statusBarBrightness: themeState.isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: background,
    systemNavigationBarIconBrightness: iconBrightness,
  );
}
