import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class WavePathsLogo extends ConsumerWidget {
  const WavePathsLogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SvgPicture.asset(
      'assets/images/wavepaths_logo.svg',
      height: 28,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(themeMode.themeConfig.title, BlendMode.srcIn),
    );
  }
}
