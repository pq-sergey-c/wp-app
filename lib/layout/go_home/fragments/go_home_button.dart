import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class GoHomeButton extends ConsumerWidget {
  const GoHomeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return Positioned(
      left: layout.selectByScreenType(mobile: -5, orElse: 0),
      top: layout.selectByScreenType(
        mobile: layout.getHeightWithTopPadding(24),
        orElse: layout.getClampedHeight(percent: 5, min: 15, withTopPadding: true),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.go('/'),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
          child: Container(
            width: layout.getClampedWidth(percent: 5, min: 56),
            height: layout.getClampedHeight(percent: 7, min: 50),
            decoration: BoxDecoration(
              color: themeMode.themeConfig.primary,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
            ),
            padding: const EdgeInsets.only(left: 12, top: 12, right: 14, bottom: 12),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/house.svg',
                colorFilter: ColorFilter.mode(themeMode.themeConfig.onPrimary, BlendMode.srcIn),
                height: layout.getClampedHeight(percent: 3, min: 25),
                width: layout.getClampedHeight(percent: 3, min: 25),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
