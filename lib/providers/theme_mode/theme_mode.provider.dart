import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wp_player/providers/theme_mode/fragments/theme_mode.notifier.dart';
import 'package:wp_player/providers/theme_mode/types/theme_mode.state.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeState>(ThemeModeNotifier.new);
