import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/components/inputs/text_input.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/services/player/player.service.dart';

class ConnectPageActionLink extends HookConsumerWidget {
  const ConnectPageActionLink({required this.showLoadingPopup, required this.showFailPopup, super.key});

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    final inputController = useTextEditingController();

    final onSubmitClicked = useCallback(() async {
      if (inputController.text.trim().isEmpty) return;

      final ConnectPageCloseLoadingPopupCallback closePopup = showLoadingPopup();

      final link = inputController.text.trim();
      final isSuccessful = await PlayerService().resolveLink(link);
      if (!context.mounted) {
        closePopup();
        if (isSuccessful) await PlayerService().disconnect();
        return;
      }

      if (!isSuccessful) {
        closePopup();
        await showFailPopup(correctnessOf: "link");
        return;
      }

      if (isSuccessful) unawaited(context.push('/player'));
      closePopup();
    }, [inputController]);

    return Column(
      spacing: layout.getClampedHeight(percent: 3, min: 20),
      children: [
        SizedBox(
          width: double.infinity,
          height: layout.getClampedHeight(percent: 7, min: 65),
          child: TextInput(inputController: inputController, labelText: 'Insert link'),
        ),
        Button(
          width: double.infinity,
          height: layout.getClampedHeight(percent: 8, min: 55),
          onClicked: () async => await onSubmitClicked(),
          text: 'Submit',
        ),
      ],
    );
  }
}
