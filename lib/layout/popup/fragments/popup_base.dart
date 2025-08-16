import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/core/ux/page_scroll_behavior.dart';
import 'package:wp_player/layout/popup/types/base_popup_content.dart';
import 'package:wp_player/providers/responsive_layout/fragments/responsive_layout_model.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/providers/theme_mode/types/theme_mode.state.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class PopupBase extends ConsumerWidget {
  const PopupBase({required this.content, required this.action, super.key, this.withBackgroundOverlay = true});

  final bool withBackgroundOverlay;
  final BasePopupContent content;
  final Widget action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    final List<Widget> popupMainContent = _getContent(themeMode, layout);

    return Stack(
      children: [
        Container(
          width: layout.screenWidth,
          height: layout.screenHeight,
          decoration: BoxDecoration(
            color: withBackgroundOverlay ? AppColors.black.withAlpha(190) : AppColors.transparent,
          ),
        ),
        Align(
          alignment: layout.selectByScreenType(mobile: Alignment.bottomCenter, orElse: Alignment.center),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: layout.getClampedWidth(percent: 90, max: 500),
              maxHeight: layout.getClampedHeight(percent: 60, min: 700),
              minHeight: layout.getClampedHeight(
                percent: layout.selectByScreenType(mobile: 25, orElse: 28),
                max: 275,
                min: 20,
              ),
            ),
            margin: layout.selectByScreenType(mobile: const EdgeInsets.only(bottom: 24), orElse: EdgeInsets.zero),
            padding: EdgeInsets.all(layout.selectByScreenType(mobile: 16, orElse: 20)),
            decoration: BoxDecoration(
              color: themeMode.getColorByMode(dark: themeMode.themeConfig.background, light: AppColors.white),
              borderRadius: BorderRadius.circular(16),
              border: themeMode.getByMode(
                light: BoxBorder.all(color: AppColors.transparent, width: 2),
                dark: BoxBorder.all(color: AppColors.indigoDusk, width: 2),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: layout.selectByScreenType(mobile: 24, orElse: 16),
              children: [...popupMainContent, action],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _getContent(ThemeModeState themeMode, ResponsiveLayout layout) {
    switch (content) {
      case final BasePopupTextContent content:
        return _textContent(themeMode, layout, content);
      case final BasePopupWidgetContent content:
        return [content.content.widget];
    }
  }

  static List<Widget> _textContent(
    ThemeModeState themeMode,
    ResponsiveLayout layout,
    BasePopupTextContent popupContent,
  ) {
    final children = [
      // Title
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          popupContent.icon,
          Expanded(
            child: Text(
              popupContent.content.title,
              style: TextStyle(
                decoration: TextDecoration.none,
                color: popupContent.titleColor ?? themeMode.themeConfig.title,
                fontSize: layout.getTextSize(TextSizes.xl),
                fontVariations: [FontVariationWeight.w400()],
                fontFamily: themeMode.themeConfig.fontFamily,
              ),
            ),
          ),
        ],
      ),

      // Message
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: layout.getClampedHeight(percent: 40, min: 20)),
        child: ScrollConfiguration(
          behavior: pageScrollBehaviorWithScrollBar,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Text.rich(
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontVariations: [FontVariationWeight.w300()],
                  fontFamily: themeMode.themeConfig.fontFamily,
                  fontSize: layout.getTextSize(TextSizes.sm),
                  color: themeMode.themeConfig.subtext,
                  height: 1.375,
                ),
                popupContent.content.message,
              ),
            ),
          ),
        ),
      ),
    ];
    return children;
  }
}
