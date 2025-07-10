import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/core/ux/page_scroll_behavior.dart';
import 'package:wp_player/styles/colors/colors.dart';

class ScrollablePageShell extends ConsumerWidget {
  const ScrollablePageShell({this.child, super.key});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.blueIron, toolbarHeight: 0),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: pageScrollBehaviorWithoutScrollBar,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}
