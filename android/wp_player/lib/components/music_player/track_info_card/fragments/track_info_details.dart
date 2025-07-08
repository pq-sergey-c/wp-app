import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';

class TrackInfoDetails extends ConsumerWidget {
  final SessionInfo sessionInfo;

  const TrackInfoDetails({required this.sessionInfo, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: themeMode.themeConfig.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child:
                      sessionInfo.imageUrl.isNotEmpty
                          ? Image.network(sessionInfo.imageUrl, fit: BoxFit.cover)
                          : ColoredBox(
                            color: AppColors.greyPebble,
                            child: Icon(Icons.music_note, size: 24, color: themeMode.themeConfig.primary),
                          ),
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Streaming by",
                          style: TextStyle(
                            fontSize: layout.getTextSize(TextSizes.normal),
                            color: themeMode.themeConfig.subtext,
                            height: 1.325,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.info_outline_rounded,
                          size: 22,
                          color: themeMode.getColorByMode(dark: AppColors.white, light: AppColors.indigoMist),
                        ),
                      ],
                    ),
                    Text(
                      sessionInfo.artist,
                      style: TextStyle(
                        fontSize: layout.getTextSize(TextSizes.xl),
                        fontVariations: [FontVariationWeight.w700()],
                        color: themeMode.themeConfig.text,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4.0), // TODO: find solution without padding
            child: Text(
              sessionInfo.deviceInfo,
              style: TextStyle(
                fontSize: layout.getTextSize(TextSizes.normal),
                color: themeMode.themeConfig.subtext,
                fontVariations: [FontVariationWeight.w600()],
              ),
            ),
          ),

          Text(
            sessionInfo.description,
            style: TextStyle(fontSize: layout.getTextSize(TextSizes.normal), color: themeMode.themeConfig.subtext),
          ),
        ],
      ),
    );
  }
}
