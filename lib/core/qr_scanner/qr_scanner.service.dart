import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/utils/data_parse/http_link_parsing/check_translate_http_link_to_player_link.dart';

bool isQRScannerSupportedOnPlatform() {
  return Platform.isAndroid;
  // TODO: unncomment to support IOS
  // return Platform.isAndroid || Platform.isIOS;
}

extension ResolveQR on PlayerService {
  Future<bool> scanResolveQR(BuildContext context, {void Function()? onSuccessScan}) async {
    final String? qrLink = await context.push<String?>('/standalone/scan_qr');
    if (qrLink == null) return false;

    final String? playerLink = checkTranslateHTTPLinkToPlayerLink(qrLink);
    if (playerLink == null) return false;

    onSuccessScan?.call();
    return await resolveLink(playerLink);
  }
}
