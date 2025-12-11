import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/styles/colors/colors.dart';

class ConnectPageIcon extends ConsumerWidget {
  const ConnectPageIcon({
    required this.iconPath,
    required this.isSmallVariant,
    super.key,
  });

  final String iconPath;
  final bool isSmallVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final layout = ref.watch(responsiveLayoutProvider);

    // final iconSize = min(
    //   layout.getClampedWidth(percent: 5),
    //   layout.getClampedHeight(percent: 5),
    // ).clamp(40.0, 40.0);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadiusGeometry.circular(16),
      ),
      child: Align(
        child: SvgPicture.asset(
          width: 25,
          height: 25,
          iconPath,
          colorFilter: const ColorFilter.mode(
            AppColors.blueIron,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
