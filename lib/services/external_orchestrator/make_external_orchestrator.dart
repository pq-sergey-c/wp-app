import 'dart:async';
import 'dart:io';

import 'package:wp_player/core/permissions/request_notification_permissions.dart';
import 'package:wp_player/services/external_orchestrator/external_orchestrator.service.interface.dart';
import 'package:wp_player/services/external_orchestrator/implementations/foreground_service_runner/foreground_service_runner.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/implementations/main_isolate_runner/main_isolate_runner.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/callbacks.external_orchestrator.dart';
import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_score.player.dart';
import 'package:wp_player/utils/logger/logger.dart';

Future<IExternalOrchestrator> makeOnlineExternalOrchestrator({
  required CallbackSetBroadcastState callbackSetBroadcastState,
  required CallbackSetVoiceovers callbackSetVoiceovers,
  required CallbackSetSessionDuration callbackSetSessionDuration,
  required CallbackSetPlaybackTime callbackSetPlaybackTime,
  required ExternalOrchestratorEnvironment environment,
  required String broadcastId,
  required String sessionId,
  required SessionScore sessionScore,
  required String artist,
  required String sessionName,
}) async {
  if (Platform.isWindows) {
    return ExternalOrchestratorRunnerMainIsolate.online(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetVoiceovers: callbackSetVoiceovers,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      environment: environment,
      broadcastId: broadcastId,
      sessionId: sessionId,
    );
  }

  final bool hasNotificationPermission =
      await RequestNotificationPermissions.isGrantedPermissionsToStartForegroundService();

  if (!hasNotificationPermission) {
    logConsole.i("Notification permission denied for orchestrator. Falling back to main isolate version");
    return ExternalOrchestratorRunnerMainIsolate.online(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetVoiceovers: callbackSetVoiceovers,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      environment: environment,
      broadcastId: broadcastId,
      sessionId: sessionId,
    );
  }

  return ExternalOrchestratorRunnerForegroundService.online(
    callbackSetBroadcastState: callbackSetBroadcastState,
    callbackSetVoiceovers: callbackSetVoiceovers,
    callbackSetSessionDuration: callbackSetSessionDuration,
    callbackSetPlaybackTime: callbackSetPlaybackTime,
    environment: environment,
    broadcastId: broadcastId,
    sessionId: sessionId,
    sessionScore: sessionScore,
    artist: artist,
    sessionName: sessionName,
  );
}

Future<IExternalOrchestrator> makeOfflineExternalOrchestrator({
  required CallbackSetBroadcastState callbackSetBroadcastState,
  required CallbackSetSessionDuration callbackSetSessionDuration,
  required CallbackSetPlaybackTime callbackSetPlaybackTime,
  required String sessionId,
  required SessionBroadcastState? broadcastState,
  required Duration sessionDuration,
  required SessionScore sessionScore,
  required String artist,
  required String sessionName,
}) async {
  if (Platform.isWindows) {
    return ExternalOrchestratorRunnerMainIsolate.offline(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      sessionId: sessionId,
      broadcastState: broadcastState,
      sessionDuration: sessionDuration,
    );
  }

  final bool hasNotificationPermission =
      await RequestNotificationPermissions.isGrantedPermissionsToStartForegroundService();

  if (!hasNotificationPermission) {
    logConsole.i("Notification permission denied for orchestrator. Falling back to main isolate version");
    return ExternalOrchestratorRunnerMainIsolate.offline(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      sessionId: sessionId,
      broadcastState: broadcastState,
      sessionDuration: sessionDuration,
    );
  }

  return ExternalOrchestratorRunnerForegroundService.offline(
    callbackSetBroadcastState: callbackSetBroadcastState,
    callbackSetSessionDuration: callbackSetSessionDuration,
    callbackSetPlaybackTime: callbackSetPlaybackTime,
    sessionId: sessionId,
    broadcastState: broadcastState,
    sessionDuration: sessionDuration,
    sessionScore: sessionScore,
    artist: artist,
    sessionName: sessionName,
  );
}
