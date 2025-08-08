import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/core/qr_scanner/qr_scanner.service.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';

class ConnectPageActionScanner extends HookConsumerWidget {
  const ConnectPageActionScanner({required this.showLoadingPopup, required this.showFailPopup, super.key});

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    final onScanClicked = useCallback(() async {
      ConnectPageCloseLoadingPopupCallback? closePopup;

      final isSuccessful = await PlayerService().scanResolveQR(
        context,
        onSuccessScan: () => closePopup = showLoadingPopup(),
      );

      if (!context.mounted) {
        closePopup?.call();
        if (isSuccessful) await PlayerService().disconnect();
        return;
      }

      if (!isSuccessful) {
        closePopup?.call();
        await showFailPopup(correctnessOf: "QR code");
        return;
      }

      if (isSuccessful) unawaited(context.push('/player'));
      closePopup?.call();
    }, []);

    return Button(
      onClicked: () async => await onScanClicked(),
      text: 'Scan QR code',
      width: layout.getClampedWidth(percent: 80, max: 500),
      height: layout.getClampedHeight(percent: 9, min: 60),
    );
  }
}
