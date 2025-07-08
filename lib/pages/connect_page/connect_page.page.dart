import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/pages/connect_page/fragments/connect_page_content.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class ConnectPage extends HookConsumerWidget {
  const ConnectPage({required this.userRole, super.key});

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    // Popups
    ConnectPageCloseLoadingPopupCallback showLoadingPopup() {
      return popup.addPopupLoading(title: "Please wait", message: const TextSpan(text: "Connecting to the server..."));
    }

    Future<void> showFailPopup({required String correctnessOf}) {
      return popup.addPopupNotification(
        title: "Failed to connect to server",
        buttonText: "Understood",
        message: TextSpan(
          children: [
            const TextSpan(text: 'Please check whether the '),
            TextSpan(text: correctnessOf, style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
            const TextSpan(text: ' is correct and ensure your '),
            TextSpan(text: 'internet connection', style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
            const TextSpan(text: " is stable\n\nIt's also possible that the "),
            TextSpan(text: 'server', style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
            const TextSpan(text: ' is temporarily unavailable, so if the issue persists, please '),
            TextSpan(text: 'try again later', style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
          ],
        ),
      );
    }

    // Style
    final double topPadding = layout.selectByScreenType(
      mobile: 24,
      orElse: layout.getClampedHeight(percent: 5, min: 15),
    ); // based on top position of home button
    final double bottomPadding = layout.getClampedHeight(percent: 6, min: 20, max: 30);

    // ---
    return ScrollablePageShell(
      child: Padding(
        padding: EdgeInsetsGeometry.only(
          left: layout.getClampedWidth(percent: 8, max: 50),
          right: layout.getClampedWidth(percent: 8, max: 50),
          top: topPadding,
          bottom: bottomPadding,
        ),
        child: SizedBox(
          width: layout.screenWidth,
          height: max(
            layout.screenHeight - bottomPadding - layout.paddingTop - topPadding,
            layout.selectByScreenType(desktop: 500, orElse: 600),
          ),
          child: ConnectPageContent(
            showLoadingPopup: showLoadingPopup,
            showFailPopup: showFailPopup,
            userRole: userRole,
          ),
        ),
      ),
    );
  }
}
