import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/utils/logger/logger.dart';

class ExternalLinkBox extends ConsumerWidget {
  const ExternalLinkBox({required this.text, required this.externalLink, this.width, this.height, super.key});

  final TextSpan text;
  final Uri externalLink;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return SizedBox(
      width: width ?? layout.getClampedWidth(percent: 95, max: 500),
      height: height,
      child: OutlinedButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            themeMode.getColorByMode(dark: AppColors.transparent, light: AppColors.white),
          ),
          side: WidgetStateProperty.all<BorderSide>(
            BorderSide(color: themeMode.getColorByMode(dark: AppColors.white, light: AppColors.transparent)),
          ),
          padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsetsGeometry.all(20)),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        onPressed: () async {
          if (!await launchUrl(externalLink)) {
            logConsole.f("Failed to launch external link: $externalLink");
          }
        },
        child: Row(
          spacing: 24,
          children: [
            Expanded(
              child: Text.rich(
                text,
                style: TextStyle(
                  color: themeMode.getColorByMode(
                    dark: themeMode.themeConfig.text,
                    light: themeMode.themeConfig.subtext,
                  ),
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/images/external_link.svg',
              colorFilter: ColorFilter.mode(themeMode.themeConfig.text, BlendMode.srcIn),
              height: layout.getTextSize(TextSizes.xl2),
            ),
          ],
        ),
      ),
    );
  }
}
