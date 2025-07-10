import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:wp_player/layout/popup/fragments/popup_base.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class PopupLoading extends ConsumerWidget {
  const PopupLoading(this.config, {super.key, this.withBackgroundOverlay = true});
  final PopupLoadingConfig config;
  final bool withBackgroundOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return PopupBase(
      config,
      icon: Icon(
        Icons.access_time_rounded,
        size: layout.getTextSize(TextSizes.xl) * 1.525,
        color: themeMode.themeConfig.title,
      ),
      withBackgroundOverlay: withBackgroundOverlay,
      action: SizedBox(child: LoadingAnimationWidget.staggeredDotsWave(color: themeMode.themeConfig.text, size: 50)),
    );
  }
}
