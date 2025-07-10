import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/core/qr_scanner/qr_scanner.service.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class PleaseNoteText extends ConsumerWidget {
  const PleaseNoteText({required this.userRole, super.key});

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    final text =
        userRole == UserRole.listener
            ? const TextSpan(
              text:
                  "Please note: Listeners can stream music for free but only via the link "
                  "or QR code received by your provider",
            )
            : const TextSpan(
              text:
                  "This app is for streaming music only. You'll need a Wavepaths account to "
                  "launch and control sessions from your browser\n",
              children: [
                TextSpan(
                  text: "Create one for free – no card details required",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.yellowAmber,
                    decorationThickness: 2,
                  ),
                ),
              ],
            );

    late final TextSizes textSize;
    if (!isQRScannerSupportedOnPlatform()) {
      textSize = layout.selectByScreenType(desktop: TextSizes.sm, tablet: TextSizes.xs, mobile: TextSizes.xs2);
    } else {
      textSize = TextSizes.sm;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Text.rich(
        style: TextStyle(fontSize: layout.getTextSize(textSize), color: themeMode.themeConfig.subtext),
        textAlign: TextAlign.center,
        text,
      ),
    );
  }
}
