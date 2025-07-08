import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/hooks/core/router/use_on_page_pop.dart';
import 'package:wp_player/pages/player/fragments/music_player.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

class PlayerPage extends HookConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    useOnPagePop(ref, onPop: () => Future.microtask(() => PlayerService().disconnect()));

    // ----------------------
    // Network issues

    final closeNetworkIssuePopup = useRef<void Function()?>(null);
    useEffect(() {
      void onConnectionChanged() {
        final isInterrupted = PlayerService().isConnectionInterruptedListenable?.value ?? true;
        final hasPopup = closeNetworkIssuePopup.value != null;

        if (!isInterrupted && hasPopup) {
          closeNetworkIssuePopup.value!();
          closeNetworkIssuePopup.value = null;
        } else if (isInterrupted && !hasPopup) {
          closeNetworkIssuePopup.value = popup.addPopupNetworkIssues(
            title: "Trying to reconnect...",
            message: TextSpan(
              text: "Encountered network error. Please recheck your ",
              children: [
                TextSpan(text: "internet signal", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
              ],
            ),
          );
        }
      }

      final listenable = PlayerService().isConnectionInterruptedListenable?..addListener(onConnectionChanged);
      return () => listenable?.removeListener(onConnectionChanged);
    }, []);

    // ----------------------

    return ScrollablePageShell(
      child: Padding(
        padding: EdgeInsets.only(
          top: layout.selectByScreenType(
            mobile: 24,
            orElse: layout.getClampedHeight(percent: 5, min: 15, withTopPadding: true),
          ),
        ),
        child: const MusicPlayerPage(),
      ),
    );
  }
}
