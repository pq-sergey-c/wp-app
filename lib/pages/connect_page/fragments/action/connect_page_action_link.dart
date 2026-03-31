import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/components/controls/button.dart';
import 'package:wp_player/components/inputs/link_input.dart';
import 'package:wp_player/pages/connect_page/types/connect_page_show_popup.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';
import 'package:wp_player/services/player/player.service.dart';

class ConnectPageActionLink extends HookConsumerWidget {
  const ConnectPageActionLink({
    required this.showLoadingPopup,
    required this.showFailPopup,
    this.trailingActions = const <Widget>[],
    super.key,
  });

  final ConnectPageShowLoadingPopupCallback showLoadingPopup;
  final ConnectPageShowNotificationPopup showFailPopup;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(responsiveLayoutProvider);

    final inputController = useTextEditingController();

    final onSubmitClicked = useCallback(() async {
      if (inputController.text.trim().isEmpty) return;

      final ConnectPageCloseLoadingPopupCallback closePopup =
          showLoadingPopup();

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
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: layout.getClampedHeight(percent: 7, min: 65),
          ),
          child: LinkInput(
            inputController: inputController,
            labelText: 'Insert link',
            onSubmitted: (_) => unawaited(onSubmitClicked()),
            schemas: [
              RegExp(r'(wavepaths2:\/\/\S+)', caseSensitive: false),
              RegExp(
                r'(https:\/\/guide\.wavepaths\.com\S*)',
                caseSensitive: false,
              ),
            ],
            trailingActions: trailingActions,
            maxLines: null,
            fontSize: layout.getTextSize(TextSizes.sm),
          ),
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
