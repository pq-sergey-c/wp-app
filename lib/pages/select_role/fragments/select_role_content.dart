import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wp_player/pages/select_role/fragments/select_role_button.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/styles/fonts/fonts.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class SelectRoleContent extends HookConsumerWidget {
  const SelectRoleContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    final getVersionFuture = useMemoized(() => PackageInfo.fromPlatform().then((result) => result));
    final version = useFuture(getVersionFuture);

    final buttons = [
      SelectRoleButton(
        imagePath: 'assets/images/illustrations/listener_illustration.png',
        label: "I am a Listener",
        goToOnClickRoute: '/connect/${UserRole.listener.value}',
      ),
      SelectRoleButton(
        imagePath: 'assets/images/illustrations/provider_illustration.png',
        label: "I am a Provider",
        goToOnClickRoute: '/connect/${UserRole.provider.value}',
      ),
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsetsGeometry.only(top: layout.getClampedHeight(percent: 1.5, min: 10)),
            width: layout.screenWidth,
            child: SvgPicture.asset(
              'assets/images/wavepaths_logo.svg',
              height: 44,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(themeMode.themeConfig.title, BlendMode.srcIn),
            ),
          ),

          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: layout.selectByScreenType(
                mobile: layout.getClampedWidth(percent: 75),
                orElse: layout.getClampedWidth(percent: 60),
              ),
            ),
            child: Text(
              "Helps you enter a state of calm and self-reflection",
              style: TextStyle(
                fontFamily: Fonts.dancingScript,
                fontSize: layout.selectByScreenType(
                  mobile: layout.getTextSize(TextSizes.xl3),
                  tablet: layout.getTextSize(TextSizes.xl4),
                  desktop: layout.getTextSize(TextSizes.xl5),
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              style: TextStyle(
                fontFamily: Fonts.inter,
                fontSize: layout.getTextSize(TextSizes.sm),
                color: themeMode.themeConfig.subtext,
              ),
              children: [
                const TextSpan(text: "Please note: To ensure best audio quality and stability, this app is "),
                TextSpan(
                  text: 'only ',
                  style: TextStyle(fontVariations: [FontVariationWeight.w700()], fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: "for streaming music"),
              ],
            ),
          ),

          layout.selectByScreenType(
            mobile: Column(spacing: 32, children: buttons),
            orElse: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: layout.getClampedWidth(percent: 5),
              children: buttons,
            ),
          ),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.getClampedWidth(percent: 50, min: 200)),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: "Try Wavepaths for free ",
                style: TextStyle(
                  fontFamily: Fonts.inter,
                  fontSize: layout.getTextSize(TextSizes.normal),
                  color: themeMode.themeConfig.text,
                ),

                children: const [
                  TextSpan(
                    text: "(no card details needed)",
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.yellowAmber,
                      decorationThickness: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Text(
            version.data == null ? "" : "v.${version.data!.version} (${version.data!.buildNumber})",
            style: TextStyle(
              color: themeMode.themeConfig.text,
              fontSize: layout.getTextSize(TextSizes.xs),
              fontFamily: Fonts.inter,
            ),
          ),
        ],
      ),
    );
  }
}
