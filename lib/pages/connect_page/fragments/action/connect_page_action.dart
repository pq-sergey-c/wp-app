import 'package:flutter/material.dart';
import 'package:wp_player/core/qr_scanner/qr_scanner.service.dart';
import 'package:wp_player/pages/connect_page/fragments/action/connect_page_action_link.dart';
import 'package:wp_player/pages/connect_page/fragments/action/connect_page_action_scanner.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';

class ConnectPageAction extends StatelessWidget {
  const ConnectPageAction({required this.showLoadingPopup, required this.showFailPopup, super.key});

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;

  @override
  Widget build(BuildContext context) {
    final isScanner = isQRScannerSupportedOnPlatform();
    if (isScanner) {
      return ConnectPageActionScanner(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup);
    }

    return ConnectPageActionLink(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup);
  }
}
