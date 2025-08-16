import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/layout/popup/fragments/popup_base.dart';
import 'package:wp_player/layout/popup/types/base_popup_content.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class PopupYesNo extends ConsumerWidget {
  const PopupYesNo(this.config, {super.key, this.withBackgroundOverlay = true});
  final PopupYesNoConfig config;
  final bool withBackgroundOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final BasePopupContent content = switch (config.content) {
      final PopupTextContent textContent => BasePopupContent.text(
        content: textContent,
        icon: Icon(
          Icons.info_outline,
          size: layout.getTextSize(TextSizes.xl) * 1.525,
          color: themeMode.themeConfig.title,
        ),
      ),
      final PopupWidgetContent widgetContent => BasePopupContent.widget(content: widgetContent),
    };

    return PopupBase(
      content: content,
      withBackgroundOverlay: withBackgroundOverlay,
      action: SizedBox(
        height: 56,
        child: Row(
          spacing: 20,
          children: [
            // No button
            Expanded(
              child: Button(
                onClicked: config.noCallback,
                text: config.noText,
                textStyle: TextStyle(
                  fontSize: layout.getTextSize(TextSizes.normal),
                  fontFamily: themeMode.themeConfig.fontFamily,
                  color: themeMode.themeConfig.onPrimary,
                  fontVariations: [FontVariationWeight.w700()],
                ),
                buttonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    themeMode.getColorByMode(
                      dark: themeMode.themeConfig.background,
                      light: themeMode.themeConfig.primary,
                    ),
                  ),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(16),
                      side: themeMode.getByMode(
                        light: BorderSide.none,
                        dark: BorderSide(color: themeMode.themeConfig.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Yes button
            Expanded(
              child: Button(
                onClicked: config.yesCallback,
                text: config.yesText,
                textStyle: TextStyle(
                  fontSize: layout.getTextSize(TextSizes.normal),
                  fontFamily: themeMode.themeConfig.fontFamily,
                  color: themeMode.themeConfig.onPrimary,
                  fontVariations: [FontVariationWeight.w700()],
                ),
                buttonStyle: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    themeMode.getColorByMode(dark: themeMode.themeConfig.primary, light: AppColors.indigoMist),
                  ),
                  shape: WidgetStatePropertyAll<OutlinedBorder>(
                    RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(16)),
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
