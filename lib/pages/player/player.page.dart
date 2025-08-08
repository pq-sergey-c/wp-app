// TODO: refactor - maybe into some specific folder for this page - like popups?
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/containers/scrollable_page_shell.dart';
import 'package:wp_player/hooks/core/router/use_on_page_pop.dart';
import 'package:wp_player/pages/player/fragments/music_player.dart';
import 'package:wp_player/providers/go_home_callback/go_home_callback.provider.dart';
import 'package:wp_player/providers/popup/fragments/popup_notifier.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class PlayerPage extends HookConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);
    final popup = ref.watch(popupProvider.notifier);

    infoPopup(popup);
    confirmationPopup(context, ref, popup);
    networkIssuesPopup(popup);

    return ScrollablePageShell(
      child: Padding(
        padding: EdgeInsets.only(
          top: layout.selectByScreenType(
            mobile: 24,
            orElse: layout.getClampedHeight(percent: 5, min: 15, withTopPadding: true),
          ),
          bottom: 24,
        ),
        child: const MusicPlayerPage(),
      ),
    );
  }

  void infoPopup(PopupNotifier popup) {
    useEffect(() {
      unawaited(
        Future.microtask(
          () async => await popup.addPopupNotification(
            title: 'Setup Requirements',
            buttonText: 'I understand',
            message: TextSpan(
              children: [
                TextSpan(text: "Internet", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Ensure your connection is stable, reliable & reasonably fast"),

                TextSpan(text: "\n\nAudio", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Avoid using bluetooth to protect audio quality and playback stability"),

                TextSpan(text: "\n\nBattery", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(
                  text:
                      ": Ensure this device has sufficient battery power and is connected to a charger when running long sessions",
                ),

                TextSpan(text: "\n\nNon-disturb", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Ensure this device cannot disrupt the music via calls or app notifications"),

                if (PlayerService().sessionInformation.userRole == UserRole.provider) ...[
                  TextSpan(text: "\n\nStreaming-only", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                  const TextSpan(text: ": Use your browser to launch and control sessions"),
                ],
              ],
            ),
          ),
        ),
      );
      return;
    }, []);
  }

  void confirmationPopup(BuildContext context, WidgetRef ref, PopupNotifier popup) {
    // TODO: assess this part - cause I strongly don't like it

    final canClosePageCallback = useCallback(() async {
      final toStop = await popup.addPopupYesNo(
        title: "Warning",
        yesText: "Yes",
        noText: "No",
        message: const TextSpan(text: "This action will stop streaming the music. Do you want to continue?"),
      );
      if (toStop) {
        await PlayerService().disconnect();
      }
      return toStop;
    }, []);

    final isPopped = useRef(false);

    useOnPagePop(
      ref,
      initialCanPop: false,
      onPop: (setCanClosePageCallback) async {
        if (isPopped.value || !context.canPop() || !context.mounted) {
          setCanClosePageCallback(canPop: false);
          return;
        }

        // This set of [isPopped] both prevent strange re run of removed Pop hook - possibly due to async (maybe rename though)
        isPopped.value = true;

        final canPop = await canClosePageCallback();
        if (!canPop || !context.mounted) {
          setCanClosePageCallback(canPop: false);
          isPopped.value = false;
          return;
        }

        setCanClosePageCallback(canPop: true);
        context.pop();
      },
    );

    useEffect(() {
      StateController<Future<({bool canGoHome})> Function()?>? callbackProviderNotifier;
      bool disposed = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        callbackProviderNotifier = ref.read(goHomeCallbackProvider.notifier);

        if (disposed) return;
        callbackProviderNotifier!.state = () async => (canGoHome: await canClosePageCallback());
      });

      return () {
        disposed = true;
        callbackProviderNotifier?.state = null;
      };
    }, []);
  }

  void networkIssuesPopup(PopupNotifier popup) {
    final closeNetworkIssuePopup = useRef<void Function()?>(null);
    useEffect(() {
      void onConnectionChanged() {
        final isInterrupted = PlayerService().isConnectionInterruptedListenable?.value ?? false;
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
  }
}
