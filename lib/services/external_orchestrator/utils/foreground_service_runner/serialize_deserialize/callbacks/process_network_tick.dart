import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';

Map<String, dynamic> serializeProcessNetworkTick(NetworkTick tick) => {
  'type': ForegroundServiceCallback.processNetworkTick.value,
  'data': tick.toJson(),
};

NetworkTick deserializeProcessNetworkTick(Map<String, dynamic> json) {
  final data = json["data"];
  if (data is! Map<String, dynamic>) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeProcessNetworkTick");
  }
  final result = NetworkTick.fromJson(data);
  if (result == null) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeProcessNetworkTick");
  }
  return result;
}
