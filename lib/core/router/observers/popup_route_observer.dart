import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';

class PopupRouteObserver extends NavigatorObserver {
  PopupRouteObserver(this.ref);

  final WidgetRef ref;

  @override
  void didPop(Route route, Route? previousRoute) {
    final notifier = ref.read(popupProvider.notifier);

    ref.read(popupProvider).forEach((key, popup) {
      popup.onForcedClosedCallback?.call();
      notifier.removePopup(key);
    });
  }
}
