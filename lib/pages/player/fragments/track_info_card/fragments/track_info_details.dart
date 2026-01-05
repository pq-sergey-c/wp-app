import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/initials_avatar/initials_avatar.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';
import 'package:wp_player/styles/fonts/fonts.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class TrackInfoDetails extends ConsumerWidget {
  final SessionInfo sessionInfo;

  const TrackInfoDetails({required this.sessionInfo, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final typeTitle = sessionInfo.sessionType.getReadableName;
    final actionTitle = switch (sessionInfo.userRole) {
      UserRole.provider => "Streaming by",
      UserRole.listener => "Provided by",
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: [
        // Session type
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            const Icon(Icons.circle, color: AppColors.greenSoft, size: 14),
            Text(
              typeTitle,
              style: TextStyle(
                fontSize: layout.getTextSize(TextSizes.sm),
                fontVariations: [FontVariationWeight.w400()],
                color: themeMode.themeConfig.text,
                fontFamily: Fonts.inter,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),

        // Provided / streaming by
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
                        ? Image.network(
                            sessionInfo.imageUrl, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return InitialsAvatar(
                                name: sessionInfo.artist,
                                size: 54,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return ColoredBox(
                                color: AppColors.greyFog,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : InitialsAvatar(
                            name: sessionInfo.artist,
                            size: 54,
                          ),
              ),
            ),

            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actionTitle,
                    style: TextStyle(
                      fontSize: layout.getTextSize(TextSizes.sm),
                      fontVariations: [FontVariationWeight.w300()],
                      fontFamily: Fonts.inter,
                      color: themeMode.themeConfig.subtext,
                      height: 1.1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    sessionInfo.artist,
                    style: TextStyle(
                      fontSize: layout.getTextSize(TextSizes.lg),
                      fontVariations: [FontVariationWeight.w700()],
                      fontFamily: Fonts.inter,
                      color: themeMode.themeConfig.text,
                      height: 1.1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Device
        if (sessionInfo.userRole != UserRole.provider) ...{
          Text(
            sessionInfo.deviceInfo,
            style: TextStyle(
              fontSize: layout.getTextSize(TextSizes.normal),
              color: themeMode.themeConfig.text,
              fontVariations: [FontVariationWeight.w500()],
              fontFamily: Fonts.inter,
              decoration: TextDecoration.none,
            ),
          ),
        },

        // Other text
        Text(
          sessionInfo.sessionDescription,
          style: TextStyle(
            fontSize: layout.getTextSize(TextSizes.sm),
            fontVariations: [FontVariationWeight.w300()],
            fontFamily: Fonts.inter,
            color: themeMode.themeConfig.text,
            height: 1.5,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
