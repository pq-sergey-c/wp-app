import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeProvider = ref.watch(themeModeProvider.notifier);
    final layout = ref.watch(responsiveLayoutProvider);

    return Positioned(
      right: layout.selectByScreenType(mobile: -5, orElse: 0),
      top: layout.selectByScreenType(
        mobile: layout.getHeightWithTopPadding(24),
        orElse: layout.getClampedHeight(percent: 5, min: 15, withTopPadding: true),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: themeProvider.toggleTheme,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
          child: Container(
            width: layout.getClampedWidth(percent: 5, min: 56),
            height: layout.getClampedHeight(percent: 7, min: 50),
            decoration: BoxDecoration(
              color: themeMode.themeConfig.primary,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(
              themeMode.getByMode(dark: Icons.light_mode_outlined, light: Icons.dark_mode_outlined),
              color: themeMode.themeConfig.onPrimary,
              size: layout.getClampedHeight(percent: 3, min: 25),
            ),
          ),
        ),
      ),
    );
  }
}
