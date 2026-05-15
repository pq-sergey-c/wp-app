import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/core/ux/page_scroll_behavior.dart';
import 'package:wp_player/core/ux/system_ui_overlay.dart';
import 'package:wp_player/pages/learn_more/fragments/learn_more_content.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class LearnMorePage extends ConsumerWidget {
  const LearnMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);
    final overlayStyle = systemUiOverlayStyleForTheme(themeMode);

    final double topPadding = layout.selectByScreenType(
      mobile: 24,
      orElse: layout.getClampedHeight(percent: 5, min: 15),
    ); // based on top position of home button
    const double bottomPadding = 20;
    const double logoHeight = 44;

    final double horizontalPadding = layout.getClampedWidth(percent: 7, max: 50);

    return Scaffold(
      backgroundColor: themeMode.themeConfig.background,
      appBar: AppBar(
        backgroundColor: themeMode.themeConfig.background,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: layout.getClampedHeight(percent: 2, min: 16),
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: SvgPicture.asset(
                'assets/images/wavepaths_logo.svg',
                height: logoHeight,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(themeMode.themeConfig.title, BlendMode.srcIn),
              ),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: pageScrollBehaviorWithoutScrollBar,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      bottom: bottomPadding + layout.paddingBottom,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: max(
                          layout.screenHeight - topPadding - layout.paddingTop - layout.paddingBottom - bottomPadding - logoHeight - topPadding,
                          600,
                        ),
                        minWidth: layout.screenWidth,
                      ),
                      child: const LearnMoreContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
