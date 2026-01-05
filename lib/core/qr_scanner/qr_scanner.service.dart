import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/utils/data_parse/http_link_parsing/check_translate_http_link_to_player_link.dart';
import 'package:wp_player/utils/platform/is_desktop.dart';

bool isQRScannerSupportedOnPlatform() {
  return !isDesktopPlatform();
}

enum ScanQrStatus { cancelled, failed, success }

extension ResolveQR on PlayerService {
  Future<ScanQrStatus> scanResolveQR(
    BuildContext context, {
    void Function()? onSuccessScan,
  }) async {
    final String? qrLink = await context.push<String?>('/standalone/scan_qr');
    if (qrLink == null) return ScanQrStatus.cancelled;

    final String? playerLink = checkTranslateHTTPLinkToPlayerLink(qrLink);
    if (playerLink == null) return ScanQrStatus.failed;

    onSuccessScan?.call();
    final didResolve = await resolveLink(playerLink);
    return didResolve ? ScanQrStatus.success : ScanQrStatus.failed;
  }
}
