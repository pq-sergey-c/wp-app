import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon_entry.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class ConnectPageInstructionNarrowListener extends ConsumerWidget {
  const ConnectPageInstructionNarrowListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      spacing: layout.getClampedHeight(percent: 2),
      children: [
        const ConnectPageIconEntry(
          iconPath: 'assets/images/scan_qr.svg',
          description: TextSpan(text: "Scan QR code"),
          descriptionTextSize: TextSizes.lg,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Expanded(child: Divider(color: themeMode.themeConfig.subtext, thickness: 1)),
            Text(
              'or',
              textAlign: TextAlign.center,
              style: TextStyle(color: themeMode.themeConfig.subtext, fontSize: layout.getTextSize(TextSizes.lg)),
            ),
            Expanded(child: Divider(color: themeMode.themeConfig.subtext, thickness: 1)),
          ],
        ),
        const ConnectPageIconEntry(
          iconPath: 'assets/images/click_link.svg',
          description: TextSpan(text: "Open session link"),
          descriptionTextSize: TextSizes.lg,
        ),
      ],
    );
  }
}
