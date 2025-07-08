import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_method.external_orchestrator.dart';

Map<String, dynamic> serializeEventMethodsForegroundService(ForegroundServiceMethod method) {
  return {'type': method.value};
}

// no need to deserialize - use get type function instead
