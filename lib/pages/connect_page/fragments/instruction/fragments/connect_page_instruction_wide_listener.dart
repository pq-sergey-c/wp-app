import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/pages/connect_page/fragments/simple/connect_page_icon_entry.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/utils/platform/is_desktop.dart';

class ConnectPageInstructionWideListener extends ConsumerWidget {
  const ConnectPageInstructionWideListener({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final showQr = !isDesktopPlatform();

    return Column(
      spacing: layout.getClampedHeight(percent: 8),
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: layout.getClampedWidth(percent: 5)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showQr)
                SizedBox(
                  width: layout.getClampedWidth(percent: 23),
                  child: const ConnectPageIconEntry(
                    iconPath: 'assets/images/scan_qr.svg',
                    description: TextSpan(text: "Scan QR code"),
                    descriptionTextSize: TextSizes.normal,
                  ),
                ),
              SizedBox(
                width: layout.getClampedWidth(percent: 23),
                child: const ConnectPageIconEntry(
                  iconPath: 'assets/images/click_link.svg',
                  description: TextSpan(text: "Or open session link"),
                  descriptionTextSize: TextSizes.normal,
                ),
              ),
              SizedBox(
                width: layout.getClampedWidth(percent: 23),
                child: const ConnectPageIconEntry(
                  iconPath: 'assets/images/listen_music.svg',
                  description: TextSpan(text: "Relax and listen to the music"),
                  descriptionTextSize: TextSizes.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
