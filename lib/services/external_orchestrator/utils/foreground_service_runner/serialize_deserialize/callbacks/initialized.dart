import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';

Map<String, dynamic> serializeEventInitializedForegroundService() {
  return {'type': ForegroundServiceCallback.initialized.value};
}

// no need to deserialize - use get type function instead
