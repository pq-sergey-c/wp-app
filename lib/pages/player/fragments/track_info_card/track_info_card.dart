import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/pages/player/fragments/track_info_card/fragments/track_info_details.dart';
import 'package:wp_player/pages/player/fragments/track_info_card/fragments/track_info_header.dart';
import 'package:wp_player/providers/popup/fragments/popup_notifier.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';

class TrackInfoCard extends ConsumerWidget {
  final SessionInfo sessionInfo;
  final PopupNotifier popupManager;

  const TrackInfoCard({required this.sessionInfo, required this.popupManager, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      decoration: BoxDecoration(color: themeMode.themeConfig.cardBackground, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: TrackInfoHeader(
        onInfoTap:
            () => unawaited(
              popupManager.addPopupNotification(
                content: PopupContent.widget(widget: TrackInfoDetails(sessionInfo: sessionInfo)),
                buttonText: "Ok",
              ),
            ),
        sessionType: sessionInfo.sessionType.getReadableName,
      ),
    );
  }
}
