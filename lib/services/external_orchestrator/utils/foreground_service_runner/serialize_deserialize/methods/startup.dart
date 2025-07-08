import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_method.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/foreground_service_startup_params.dart';

Map<String, dynamic> serializeStartupParamsOnlineForegroundService(ForegroundServiceStartupParamsOnline params) {
  return {'type': ForegroundServiceMethod.init.value, 'data': params.toJson()};
}

Map<String, dynamic> serializeStartupParamsOfflineForegroundService(ForegroundServiceStartupParamsOffline params) {
  return {'type': ForegroundServiceMethod.init.value, 'data': params.toJson()};
}

bool isOnlineStartupParamsForegroundService(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! Map<String, dynamic>) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: isOnlineStartupParams");
  }

  final isOnline = data['isOnline'];
  if (isOnline is! bool) {
    throw StateError(
      "Incoherent state in foreground service serialize/deserialize: isOnlineStartupParams got $isOnline",
    );
  }
  return isOnline;
}

// ---------------------------------------------------------------------------------------------------------------

ForegroundServiceStartupParamsOnline deserializeStartupParamsOnlineForegroundService(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! Map<String, dynamic>) {
    throw StateError(
      "Incoherent state in foreground service serialize/deserialize: deserializeStartupParamsOnlineForegroundService",
    );
  }

  final ForegroundServiceStartupParamsOnline? params = ForegroundServiceStartupParamsOnline.fromJson(data);
  if (params == null) {
    throw StateError(
      "Incoherent state in foreground service serialize/deserialize: deserializeStartupParamsOnlineForegroundService",
    );
  }

  return params;
}

ForegroundServiceStartupParamsOffline deserializeStartupParamsOfflineForegroundService(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! Map<String, dynamic>) {
    throw StateError(
      "Incoherent state in foreground service serialize/deserialize: deserializeStartupParamsOfflineForegroundService",
    );
  }

  final ForegroundServiceStartupParamsOffline? params = ForegroundServiceStartupParamsOffline.fromJson(data);
  if (params == null) {
    throw StateError(
      "Incoherent state in foreground service serialize/deserialize: deserializeStartupParamsOfflineForegroundService",
    );
  }

  return params;
}
