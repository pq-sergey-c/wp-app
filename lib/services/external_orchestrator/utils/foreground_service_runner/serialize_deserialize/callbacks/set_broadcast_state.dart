// ----------------------------
// SERIALIZERS
// ----------------------------

import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';

Map<String, dynamic> serializeSetBroadcastState(SessionBroadcastState state) => {
  'type': ForegroundServiceCallback.setBroadcastState.value,
  'data': state.toJson(),
};

SessionBroadcastState deserializeSetBroadcastState(Map<String, dynamic> json) {
  final data = json["data"];
  if (data is! Map<String, dynamic>) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetBroadcastState");
  }
  final result = SessionBroadcastState.fromJson(data);
  if (result == null) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetBroadcastState");
  }
  return result;
}
