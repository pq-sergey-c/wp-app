import 'package:wp_player/services/player.native_lib/types/native_message.native_lib.dart';

typedef WpCallbackRequestData = Future<void> Function(WpDataRequest data);

typedef WpCallbackCancelFetch = Future<void> Function(WpDataCancelRequest data);
