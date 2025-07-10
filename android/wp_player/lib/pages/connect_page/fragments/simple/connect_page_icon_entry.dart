import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class ConnectPageIconEntry extends ConsumerWidget {
  const ConnectPageIconEntry({
    required this.iconPath,
    required this.description,
    required this.descriptionTextSize,
    this.isSmallVariant = false,
    super.key,
  });

  final String iconPath;
  final TextSpan description;
  final TextSizes descriptionTextSize;
  final bool isSmallVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Row(
      spacing: 24,
      children: [
        ConnectPageIcon(iconPath: iconPath, isSmallVariant: isSmallVariant),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [description],
              style: TextStyle(
                color: themeMode.themeConfig.subtext,
                fontVariations: [FontVariationWeight.w400()],
                fontSize: layout.getTextSize(descriptionTextSize),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
