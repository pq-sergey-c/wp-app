import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/layout/popup/fragments/popup_base.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class PopupNotification extends ConsumerWidget {
  const PopupNotification(this.config, {super.key, this.withBackgroundOverlay = true});
  final PopupNotificationConfig config;
  final bool withBackgroundOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return PopupBase(
      config,
      withBackgroundOverlay: withBackgroundOverlay,
      icon: Icon(
        Icons.info_outline,
        size: layout.getTextSize(TextSizes.xl) * 1.525,
        color: themeMode.themeConfig.title,
      ),
      action: SizedBox(
        width: double.infinity,
        height: 56,
        child: Button(
          onClicked: config.buttonCallback,
          text: config.buttonText,
          buttonStyle: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(themeMode.themeConfig.primary),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
