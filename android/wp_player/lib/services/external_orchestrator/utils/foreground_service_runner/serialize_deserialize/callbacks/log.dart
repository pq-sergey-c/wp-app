import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';

Map<String, dynamic> serializeLogForegroundService(String message) {
  return {'type': ForegroundServiceCallback.log.value, 'message': message};
}

String deserializeLogForegroundService(Map<String, dynamic> json) {
  final message = json['message'];

  if (message is! String) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: serializeLogForegroundService");
  }

  return message;
}
