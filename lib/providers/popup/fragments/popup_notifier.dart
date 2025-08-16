import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';

class PopupNotifier extends Notifier<LinkedHashMap<int, PopupBaseConfig>> {
  static int _iterator = 0;
  int get _nextId => _iterator++;

  @override
  LinkedHashMap<int, PopupBaseConfig> build() {
    return LinkedHashMap();
  }

  // ---------------------------------------------------------------------------

  /// Future returns when notification is closed
  ///
  /// async return [bool] - is junk value to denote to not ignore awaiting
  Future<void> addPopupNotification({
    required PopupContent content,
    required String buttonText,
    void Function()? onForcedClosedCallback,
  }) async {
    final id = _nextId;
    final completer = Completer<void>();

    final config = PopupNotificationConfig(
      content: content,
      buttonText: buttonText,
      buttonCallback: () {
        removePopup(id);
        completer.complete();
      },
      onForcedClosedCallback: onForcedClosedCallback,
    );

    final newState = LinkedHashMap<int, PopupBaseConfig>.from(state);
    newState[id] = config;
    state = newState;

    return await completer.future;
  }

  // ---------------------------------------------------------------------------

  /// Future returns when notification is closed
  ///
  /// async return [bool] - true: when yes was pressed, false: when no was pressed
  Future<bool> addPopupYesNo({
    required PopupContent content,
    required String yesText,
    required String noText,
    void Function()? onForcedClosedCallback,
  }) async {
    final id = _nextId;
    final completer = Completer<bool>();

    final config = PopupYesNoConfig(
      content: content,
      yesText: yesText,
      noText: noText,
      yesCallback: () {
        removePopup(id);
        completer.complete(true);
      },
      noCallback: () {
        removePopup(id);
        completer.complete(false);
      },
      onForcedClosedCallback: onForcedClosedCallback,
    );

    final newState = LinkedHashMap<int, PopupBaseConfig>.from(state);
    newState[id] = config;
    state = newState;

    return await completer.future;
  }

  // ---------------------------------------------------------------------------

  /// return [void Function()] - callback to be called to close popup
  void Function() addPopupLoading({required PopupContent content, void Function()? onForcedClosedCallback}) {
    final id = _nextId;
    final config = PopupLoadingConfig(content: content, onForcedClosedCallback: onForcedClosedCallback);

    final newState = LinkedHashMap<int, PopupBaseConfig>.from(state);
    newState[id] = config;
    state = newState;

    return () => removePopup(id);
  }

  // ---------------------------------------------------------------------------

  /// return [void Function()] - callback to be called to close popup
  void Function() addPopupNetworkIssues({required PopupContent content, void Function()? onForcedClosedCallback}) {
    final id = _nextId;
    final config = PopupNetworkIssuesConfig(content: content, onForcedClosedCallback: onForcedClosedCallback);

    final newState = LinkedHashMap<int, PopupBaseConfig>.from(state);
    newState[id] = config;
    state = newState;

    return () => removePopup(id);
  }

  // ---------------------------------------------------------------------------

  void removePopup(int id) {
    if (!state.containsKey(id)) return;
    state = LinkedHashMap<int, PopupBaseConfig>.from(state)..remove(id);
  }
}
