import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:synchronized/synchronized.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/core/deep_linking/deep_linking_provider.dart';
import 'package:wp_player/pages/select_role/fragments/select_role_content.dart';
import 'package:wp_player/pages/select_role/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/utils/logger/logger.dart';

class SelectRolePage extends ConsumerWidget {
  SelectRolePage({super.key});

  final Lock _deepLinkResolve = Lock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popup = ref.watch(popupProvider.notifier);
    final layout = ref.watch(responsiveLayoutProvider);

    final double topPadding = layout.selectByScreenType(
      mobile: 24,
      orElse: layout.getClampedHeight(percent: 5, min: 15),
    ); // based on top position of home button
    const double bottomPadding = 8;
    final double horizontalPadding = layout.getClampedWidth(percent: 8, max: 50);

    // Deeplinking
    SelectRolePageCloseLoadingPopupCallback showLoadingPopup() {
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

    final link = ref.watch(deepLinkingProvider).getLinkAndMarkAsAccessed;
    _handleDeeplinking(context, link, showLoadingPopup, showFailPopup);
    // ---

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
          height: max(layout.screenHeight - topPadding - bottomPadding, 700),
          child: const SelectRoleContent(),
        ),
      ),
    );
  }

  void _handleDeeplinking(
    BuildContext context,
    String? link,
    SelectRolePageShowLoadingPopupCallback showLoadingPopup,
    SelectRolePageShowNotificationPopup showFailPopup,
  ) {
    if (link == null) return;
    logConsole.d("Got deeplinking link: $link");

    // Delay the deeplinking logic to avoid accessing popupProvider during the app's widget tree build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(() async {
        await _deepLinkResolve.synchronized(() async {
          final SelectRolePageCloseLoadingPopupCallback closePopup = showLoadingPopup();
          final isSuccessful = await PlayerService().resolveLink(link);

          if (!context.mounted) {
            closePopup();
            if (isSuccessful) await PlayerService().disconnect();
            return;
          }

          if (!isSuccessful) {
            closePopup();
            await showFailPopup(correctnessOf: "link");
            return;
          }

          unawaited(context.push('/player'));

          closePopup();
        });
      }());
    });
  }
}
