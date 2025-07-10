import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';

Map<String, dynamic> serializeSetSessionDuration(Duration duration) => {
  'type': ForegroundServiceCallback.setSessionDuration.value,
  'data': duration.inMilliseconds,
};
Duration deserializeSetSessionDuration(Map<String, dynamic> json) {
  final dataMilliseconds = json["data"];
  if (dataMilliseconds is! int) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetSessionDuration");
  }
  return Duration(milliseconds: dataMilliseconds);
}
