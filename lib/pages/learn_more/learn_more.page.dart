import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/pages/learn_more/fragments/learn_more_content.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';

class LearnMorePage extends ConsumerWidget {
  const LearnMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    final double topPadding = layout.selectByScreenType(
      mobile: 24,
      orElse: layout.getClampedHeight(percent: 5, min: 15),
    ); // based on top position of home button
    const double bottomPadding = 24;
    final double horizontalPadding = layout.getClampedWidth(percent: 7, max: 50);

    return ScrollablePageShell(
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          bottom: bottomPadding,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: SizedBox(
          width: layout.screenWidth,
          height: max(layout.screenHeight - topPadding - bottomPadding - layout.paddingTop, 700),
          child: const LearnMoreContent(),
        ),
      ),
    );
  }
}
