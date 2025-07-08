import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';

Map<String, dynamic> serializeSetPlaybackTime(Duration currentPlayTime) => {
  'type': ForegroundServiceCallback.setPlaybackTime.value,
  'data': currentPlayTime.inMilliseconds,
};

Duration deserializeSetPlaybackTime(Map<String, dynamic> json) {
  final dataMilliseconds = json["data"];
  if (dataMilliseconds is! int) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetPlaybackTime");
  }
  return Duration(milliseconds: dataMilliseconds);
}
