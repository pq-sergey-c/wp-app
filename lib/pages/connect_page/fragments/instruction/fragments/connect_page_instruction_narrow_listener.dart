import 'package:flutter/material.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon_entry.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/utils/platform/is_desktop.dart';

class ConnectPageInstructionNarrowListener extends StatelessWidget {
  const ConnectPageInstructionNarrowListener({super.key});

  @override
  Widget build(BuildContext context) {
    final showQr = !isDesktopPlatform();

    return Column(
      spacing: 16,
      children: [
        if (showQr)
          ConnectPageIconEntry(
            iconPath: 'assets/images/scan_qr.svg',
            description: TextSpan(text: "Scan the QR code"),
            descriptionTextSize: TextSizes.normal,
          ),

        ConnectPageIconEntry(
          iconPath: 'assets/images/click_link.svg',
          description: TextSpan(text: "Open session link"),
          descriptionTextSize: TextSizes.normal,
        ),
      ],
    );
  }
}
