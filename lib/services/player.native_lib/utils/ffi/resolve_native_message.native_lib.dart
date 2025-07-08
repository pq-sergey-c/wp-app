import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/native_message.native_lib.dart';

({WpNativeMessage data, WpNativeMessageType type}) resolveNativeMessage(dynamic message) {
  assert(
    message is List<dynamic>,
    "Message from native code is expected to be array of objects, advice: check native code on possible error",
  );
  if (message is! List<dynamic> || message.length < 2 || message[0] is! int) {
    throw FlutterError("Incorrect message structure from native player");
  }

  // by convection with native wrapper first value if type of message as int32
  final nativeMessageType = WpNativeMessageType.fromInt(message[0]);
  switch (nativeMessageType) {
    case WpNativeMessageType.dataRequest:
      return (
        data: WpDataRequest(message[1], message[2], DateTime.fromMillisecondsSinceEpoch(message[3])),
        type: nativeMessageType,
      );
    case WpNativeMessageType.cancelFetchRequest:
      return (data: WpDataCancelRequest(message[1]), type: nativeMessageType);
  }
}
