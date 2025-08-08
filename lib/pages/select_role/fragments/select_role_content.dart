import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/pages/select_role/utils/make_version_string.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
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

    final mainButtons = [
      Button(
        onClicked: () => context.push('/connect/${UserRole.provider.value}'),
        text: "I am a Provider",
        height: layout.isDesktop ? layout.getClampedHeight(percent: 12, max: 90, min: 70) : null,
        textStyle: TextStyle(
          fontSize: layout.selectByScreenType(
            desktop: layout.getTextSize(TextSizes.xl),
            orElse: layout.getTextSize(TextSizes.normal),
          ),
          fontFamily: themeMode.themeConfig.fontFamily,
          color: themeMode.themeConfig.onPrimary,
          fontVariations: [FontVariationWeight.w600()],
        ),
      ),
      Button(
        onClicked: () => context.push('/connect/${UserRole.listener.value}'),
        text: "I am a Listener",
        height: layout.isDesktop ? layout.getClampedHeight(percent: 12, max: 90, min: 70) : null,
        textStyle: TextStyle(
          fontSize: layout.selectByScreenType(
            desktop: layout.getTextSize(TextSizes.xl),
            orElse: layout.getTextSize(TextSizes.normal),
          ),
          fontFamily: themeMode.themeConfig.fontFamily,
          color: themeMode.themeConfig.onPrimary,
          fontVariations: [FontVariationWeight.w600()],
        ),
      ),
    ];

    final secondaryButtons = [
      Button(
        // TODO: add button subtype maybe for buttonStyle values
        onClicked: () => context.push('/learn_more'),
        text: "Learn More",
        height: layout.isDesktop ? layout.getClampedHeight(percent: 12, max: 90, min: 70) : null,
        textStyle: TextStyle(
          fontSize: layout.selectByScreenType(
            desktop: layout.getTextSize(TextSizes.xl),
            orElse: layout.getTextSize(TextSizes.normal),
          ),
          fontFamily: themeMode.themeConfig.fontFamily,
          color: themeMode.getColorByMode(dark: themeMode.themeConfig.onPrimary, light: themeMode.themeConfig.primary),
          fontVariations: [FontVariationWeight.w600()],
        ),
        buttonStyle: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(themeMode.themeConfig.background),
          side: WidgetStateProperty.all<BorderSide>(
            BorderSide(
              color: themeMode.getColorByMode(
                dark: themeMode.themeConfig.onPrimary,
                light: themeMode.themeConfig.primary,
              ),
            ),
          ),
          overlayColor: WidgetStateProperty.all<Color>(
            themeMode.getColorByMode(
              dark: const Color.fromARGB(67, 67, 69, 91), // TODO: Move to app colors
              light: const Color.fromARGB(118, 217, 217, 222),
            ),
          ),
        ),
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

          Text(
            "This app lets you stream Wavepaths music with optimal audio quality and playback stability",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontVariations: [FontVariationWeight.w400()],
              letterSpacing: 0,
              wordSpacing: -1,
              color: themeMode.themeConfig.subtext,
              fontSize: layout.selectByScreenType(
                mobile: layout.getTextSize(TextSizes.sm),
                orElse: layout.getTextSize(TextSizes.lg),
              ),
            ),
          ),

          layout.selectByScreenType(
            mobile: Column(
              spacing: 32,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: mainButtons + secondaryButtons,
            ),
            orElse: Column(
              spacing: 32,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: layout.getClampedWidth(percent: 3),
                  children: mainButtons.map((button) => Expanded(child: button)).toList(),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: secondaryButtons),
              ],
            ),
          ),

          Text(
            makeVersionString(version.data) ?? "",
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
