import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/hooks/core/router/use_on_page_pop.dart';
import 'package:wp_player/pages/player/fragments/player_content.dart';
import 'package:wp_player/providers/go_home_callback/go_home_callback.provider.dart';
import 'package:wp_player/providers/popup/fragments/popup_notifier.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

part 'popups/leaving_page_confirmation_popup.dart';
part 'popups/network_issues_popup.dart';
part 'popups/info_popup.dart';
part 'effects/navigate_home_on_session_end.dart';

class PlayerPage extends HookConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    _usePlayerPageInfoPopup(popup);
    _usePlayerPageLeavingPageConfirmationPopup(context, ref, popup);
    _usePlayerPageNetworkIssuesPopup(popup);
    _usePlayerPageNavigateHomeOnSessionEnd(context, ref);

    final double topPadding = layout.selectByScreenType(
      mobile: 24,
      orElse: layout.getClampedHeight(percent: 5, min: 15, withTopPadding: true),
    );
    const double bottomPadding = 24;

    return ScrollablePageShell(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding + layout.paddingBottom),
        child: Center(
          child: SizedBox(
            width: layout.selectByScreenType(
              mobile: layout.screenWidth - 64,
              orElse: layout.getClampedWidth(percent: 55, min: 300),
            ),
            height: max(layout.screenHeight - topPadding - layout.paddingTop - layout.paddingBottom - bottomPadding, 650),
            child: const MusicPlayer(),
          ),
        ),
      ),
    );
  }
}
