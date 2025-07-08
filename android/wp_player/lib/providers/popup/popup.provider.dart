import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/popup/fragments/popup_notifier.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';

final popupProvider = NotifierProvider<PopupNotifier, LinkedHashMap<int, PopupBaseConfig>>(() {
  return PopupNotifier();
});
