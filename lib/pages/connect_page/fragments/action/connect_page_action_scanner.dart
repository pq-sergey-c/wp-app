import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/core/qr_scanner/qr_scanner.service.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';

class ConnectPageActionScanner extends HookConsumerWidget {
  const ConnectPageActionScanner({
    required this.showLoadingPopup,
    required this.showFailPopup,
    super.key,
  });

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final theme = Theme.of(context);
    final iconSize = layout.getClampedWidth(percent: 6, min: 32, max: 40);

    final onScanClicked = useCallback(() async {
      ConnectPageCloseLoadingPopupCallback? closePopup;

      final status = await PlayerService().scanResolveQR(
        context,
        onSuccessScan: () => closePopup = showLoadingPopup(),
      );

      if (!context.mounted) {
        closePopup?.call();
        if (status == ScanQrStatus.success) await PlayerService().disconnect();
        return;
      }

      FocusScope.of(context).unfocus();

      switch (status) {
        case ScanQrStatus.cancelled:
          closePopup?.call();
          return;
        case ScanQrStatus.failed:
          closePopup?.call();
          await showFailPopup(correctnessOf: "QR code");
          return;
        case ScanQrStatus.success:
          closePopup?.call();
          unawaited(context.push('/player'));
          return;
      }
    }, [showFailPopup, showLoadingPopup]);

    return Tooltip(
      message: 'Scan QR code',
      child: IconButton(
        onPressed: () async => await onScanClicked(),
        icon: Icon(
          Icons.qr_code_scanner,
          color: theme.colorScheme.onSurface,
          size: iconSize,
        ),
        splashRadius: layout.getClampedWidth(percent: 5, min: 32, max: 40),
      ),
    );
  }
}
