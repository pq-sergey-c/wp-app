import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wp_player/pages/connect_page/fragments/action/connect_page_action.dart';
import 'package:wp_player/pages/connect_page/fragments/instruction/connect_page_instruction.dart';
import 'package:wp_player/pages/connect_page/fragments/please_note_text/please_note_text.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class ConnectPageContent extends ConsumerWidget {
  const ConnectPageContent({
    required this.showLoadingPopup,
    required this.showFailPopup,
    required this.userRole,
    super.key,
  });

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;

  final UserRole userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final themeMode = ref.watch(themeModeProvider);

    final MainAxisAlignment alignment = layout.heightBreakpoints([
      (item: MainAxisAlignment.spaceAround, maxHeight: 450),
    ], fallback: MainAxisAlignment.spaceBetween);

    return Column(
      mainAxisAlignment: alignment,
      spacing: 10,
      children: [
        Container(
          padding: EdgeInsetsGeometry.only(top: layout.getClampedHeight(percent: 1.5, min: 10)),
          width: layout.screenWidth,
          child: SvgPicture.asset(
            'assets/images/wavepaths_logo.svg',
            height: 44,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(themeMode.themeConfig.title, BlendMode.srcIn),
          ),
        ),

        ...layout.heightBreakpoints(
          [(maxHeight: 575, item: [])],
          fallback: [
            Text(
              userRole == UserRole.listener ? "Start listening" : "Start streaming as a provider",
              style: TextStyle(
                fontSize: layout.getTextSize(
                  userRole == UserRole.listener
                      ? TextSizes.xl3
                      : layout.selectByScreenType(desktop: TextSizes.xl3, orElse: TextSizes.xl2),
                ),
                fontVariations: [FontVariationWeight.w700()],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        ConnectPageInstruction(userRole: userRole),

        ...layout.heightBreakpoints(
          [
            (
              maxHeight: 750,
              item: [ConnectPageAction(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup)],
            ),
          ],
          fallback: layout.widthBreakpoints(
            [
              (
                maxWidth: 900,
                item: [
                  PleaseNoteText(userRole: userRole),
                  ConnectPageAction(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup),
                ],
              ),
            ],
            fallback: [
              ConnectPageAction(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup),
              PleaseNoteText(userRole: userRole),
            ],
          ),
        ),
      ],
    );
  }
}
