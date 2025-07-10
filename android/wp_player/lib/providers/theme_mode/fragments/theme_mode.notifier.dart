// TODO: maybe rewrite to use AsyncNotifier
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wp_player/providers/theme_mode/types/theme_mode.state.dart';

class ThemeModeNotifier extends StateNotifier<ThemeModeState> {
  static const _preferencesKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeModeState.light) {
    unawaited(_loadTheme()); // fire-and-forget
  }

  // ---------------------------------------------------------------------------

  void toggleTheme() {
    final newTheme = state.isDark ? ThemeModeState.light : ThemeModeState.dark;
    state = newTheme;

    unawaited(_saveTheme(newTheme)); // fire-and-forget
  }

  void setTheme(ThemeModeState mode) {
    state = mode;
    unawaited(_saveTheme(mode));
  }

  // ---------------------------------------------------------------------------

  // Note: Fire-and-forget saves can introduce race conditions
  // Acceptable here due to low criticality of writes
  Future<void> _saveTheme(ThemeModeState mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, mode.isDark ? 'dark' : 'light');
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_preferencesKey);

    state = saved == 'dark' ? ThemeModeState.dark : ThemeModeState.light;
  }
}
