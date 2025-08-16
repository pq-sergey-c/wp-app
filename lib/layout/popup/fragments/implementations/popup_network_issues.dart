import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:wp_player/layout/popup/fragments/popup_base.dart';
import 'package:wp_player/layout/popup/types/base_popup_content.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class PopupNetworkIssues extends ConsumerWidget {
  const PopupNetworkIssues(this.config, {super.key, this.withBackgroundOverlay = true});
  final PopupNetworkIssuesConfig config;
  final bool withBackgroundOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final accentColor = themeMode.getColorByMode(light: AppColors.redHaze, dark: AppColors.redPetal);

    final BasePopupContent content = switch (config.content) {
      final PopupTextContent textContent => BasePopupContent.text(
        content: textContent,
        icon: SvgPicture.asset(
          'assets/images/wifi-exclamation.svg',
          width: layout.getTextSize(TextSizes.xl) * 1.25,
          height: layout.getTextSize(TextSizes.xl) * 1.25,
        ),
        titleColor: accentColor,
      ),
      final PopupWidgetContent widgetContent => BasePopupContent.widget(content: widgetContent),
    };

    return PopupBase(
      content: content,
      withBackgroundOverlay: withBackgroundOverlay,
      action: SizedBox(child: LoadingAnimationWidget.staggeredDotsWave(color: themeMode.themeConfig.text, size: 50)),
    );
  }
}
