import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon_entry.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class ConnectPageInstructionNarrowProvider extends ConsumerWidget {
  const ConnectPageInstructionNarrowProvider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      spacing: 32,
      children: [
        ConnectPageIconEntry(
          iconPath: 'assets/images/listen_music.svg',
          description: TextSpan(
            text: 'Click ',
            children: [
              TextSpan(
                text: "Open app",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationColor: themeMode.themeConfig.subtext,
                  decorationThickness: 1.5,
                ),
              ),
              const TextSpan(text: " in browser"),
            ],
          ),
          descriptionTextSize: TextSizes.lg,
          isSmallVariant: true,
        ),

        const ConnectPageIconEntry(
          iconPath: 'assets/images/click_link.svg',
          description: TextSpan(text: "Or open session link"),
          descriptionTextSize: TextSizes.lg,
          isSmallVariant: true,
        ),

        const ConnectPageIconEntry(
          iconPath: 'assets/images/scan_qr.svg',
          description: TextSpan(text: "Or scan QR code"),
          descriptionTextSize: TextSizes.lg,
          isSmallVariant: true,
        ),
      ],
    );
  }
}
