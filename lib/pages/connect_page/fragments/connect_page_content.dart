import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wp_player/pages/connect_page/fragments/action/connect_page_action.dart';
import 'package:wp_player/pages/connect_page/fragments/additional_info/additional_info.dart';
import 'package:wp_player/pages/connect_page/fragments/instruction/connect_page_instruction.dart';
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
      spacing: 20,
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
          [(maxHeight: 750, item: [])],
          fallback: [
            Text(
              userRole == UserRole.listener ? "Start streaming as a Listener" : "Start streaming as a Provider",
              style: TextStyle(
                fontSize: layout.getTextSize(layout.selectByScreenType(desktop: TextSizes.xl2, orElse: TextSizes.xl)),
                fontVariations: [FontVariationWeight.w700()],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),

        ConnectPageInstruction(userRole: userRole),
        AdditionalInfo(userRole: userRole),
        ConnectPageAction(showLoadingPopup: showLoadingPopup, showFailPopup: showFailPopup),
      ],
    );
  }
}
