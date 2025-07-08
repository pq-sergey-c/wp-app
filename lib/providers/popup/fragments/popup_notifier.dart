import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';

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
    required String title,
    required String buttonText,
    required TextSpan message,
    void Function()? onForcedClosedCallback,
  }) async {
    final id = _nextId;
    final completer = Completer<void>();

    final config = PopupNotificationConfig(
      title: title,
      buttonText: buttonText,
      message: message,
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
    required String title,
    required String yesText,
    required String noText,
    required TextSpan message,
    void Function()? onForcedClosedCallback,
  }) async {
    final id = _nextId;
    final completer = Completer<bool>();

    final config = PopupYesNoConfig(
      title: title,
      yesText: yesText,
      noText: noText,
      message: message,
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
  void Function() addPopupLoading({
    required String title,
    required TextSpan message,
    void Function()? onForcedClosedCallback,
  }) {
    final id = _nextId;
    final config = PopupLoadingConfig(title: title, message: message, onForcedClosedCallback: onForcedClosedCallback);

    final newState = LinkedHashMap<int, PopupBaseConfig>.from(state);
    newState[id] = config;
    state = newState;

    return () => removePopup(id);
  }

  // ---------------------------------------------------------------------------

  /// return [void Function()] - callback to be called to close popup
  void Function() addPopupNetworkIssues({
    required String title,
    required TextSpan message,
    void Function()? onForcedClosedCallback,
  }) {
    final id = _nextId;
    final config = PopupNetworkIssuesConfig(
      title: title,
      message: message,
      onForcedClosedCallback: onForcedClosedCallback,
    );

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
