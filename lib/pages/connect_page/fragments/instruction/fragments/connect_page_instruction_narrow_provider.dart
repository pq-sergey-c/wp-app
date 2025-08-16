import 'package:flutter/material.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon_entry.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';

class ConnectPageInstructionNarrowProvider extends StatelessWidget {
  const ConnectPageInstructionNarrowProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 16,
      children: [
        ConnectPageIconEntry(
          iconPath: 'assets/images/listen_music.svg',
          description: TextSpan(text: 'Click “Open app” in browser'),
          descriptionTextSize: TextSizes.normal,
          isSmallVariant: true,
        ),

        ConnectPageIconEntry(
          iconPath: 'assets/images/click_link.svg',
          description: TextSpan(text: "Or open session link"),
          descriptionTextSize: TextSizes.normal,
          isSmallVariant: true,
        ),

        ConnectPageIconEntry(
          iconPath: 'assets/images/scan_qr.svg',
          description: TextSpan(text: "Or scan the QR code"),
          descriptionTextSize: TextSizes.normal,
          isSmallVariant: true,
        ),
      ],
    );
  }
}
