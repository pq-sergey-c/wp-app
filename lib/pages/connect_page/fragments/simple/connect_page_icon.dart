import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class ConnectPageIcon extends ConsumerWidget {
  const ConnectPageIcon({required this.iconPath, required this.isSmallVariant, super.key});

  final String iconPath;
  final bool isSmallVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    final iconSize = min(
      layout.getClampedWidth(percent: 20),
      layout.getClampedHeight(percent: isSmallVariant ? 9 : 15),
    ).clamp(layout.widthBreakpoints<double>([(item: 70, maxWidth: 900)], fallback: 90), isSmallVariant ? 90.0 : 110.0);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(iconSize / 5.5)),
      ),
      child: Align(
        child: SvgPicture.asset(
          width: iconSize / 2.5,
          height: iconSize / 2.5,
          iconPath,
          colorFilter: const ColorFilter.mode(AppColors.blueIron, BlendMode.srcIn),
        ),
      ),
    );
  }
}
