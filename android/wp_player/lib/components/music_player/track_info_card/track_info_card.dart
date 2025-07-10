import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/music_player/track_info_card/fragments/track_info_details.dart';
import 'package:wp_player/components/music_player/track_info_card/fragments/track_info_header.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';

class TrackInfoCard extends ConsumerWidget {
  final SessionInfo sessionInfo;
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const TrackInfoCard({required this.sessionInfo, required this.isExpanded, required this.onExpandToggle, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Card(
      elevation: 0,
      color: themeMode.themeConfig.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeMode.themeConfig.primary, width: 2),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Column(
        children: [
          TrackInfoHeader(isExpanded: isExpanded, onTap: onExpandToggle, sessionType: sessionInfo.sessionType),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: Align(heightFactor: isExpanded ? 1.0 : 0.0, child: TrackInfoDetails(sessionInfo: sessionInfo)),
            ),
          ),
        ],
      ),
    );
  }
}
