import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/core/ux/page_scroll_behavior.dart';
import 'package:wp_player/core/ux/system_ui_overlay.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class ScrollablePageShell extends ConsumerWidget {
  const ScrollablePageShell({this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeModeProvider);
    final overlayStyle = systemUiOverlayStyleForTheme(themeState);

    return Scaffold(
      backgroundColor: themeState.themeConfig.background,
      appBar: AppBar(
        backgroundColor: themeState.themeConfig.background,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: overlayStyle,
      ),
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: pageScrollBehaviorWithoutScrollBar,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}
