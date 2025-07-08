import 'dart:async';
import 'dart:convert';

import 'package:wp_player/services/external_orchestrator/orchestrator_network/controller.external_orchestrator.interface.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/offline_controller/offline_controller.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/online_controller/online_controller.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_method.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/foreground_service_startup_params.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/disposed.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/initialized.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/log.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/process_network_tick.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_broadcast_state.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_playback_time.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_session_duration.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_voiceovers.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/methods/startup.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/validate_message_and_get_type.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';

class ForegroundIsolate {
  ForegroundIsolate(this.sendMessageToMain);

  final Future<void> Function(Map<String, dynamic> message) sendMessageToMain;

  IExternalOrchestratorController? _controller;

  void _sendLog(String log) => sendMessageToMain(serializeLogForegroundService(log));

  // ------------------------------------------------------------------------
  // Process incoming messages from main isolate

  void onReceiveData(String dataString) {
    final data = jsonDecode(dataString);

    late final String methodTypeString;
    try {
      methodTypeString = foregroundServiceValidateMessageAndGetType(data);
    } catch (error) {
      _sendLog('onReceiveData got error: $error');
      return;
    }

    final ForegroundServiceMethod? methodType = ForegroundServiceMethod.fromString(methodTypeString);
    if (methodType == null) {
      _sendLog("Unknown method type: $methodTypeString");
      return;
    }

    _sendLog("Get method in isolate: $methodType");

    switch (methodType) {
      case ForegroundServiceMethod.init:
        _makeExternalOrchestratorController(data);
        unawaited(sendEventInitialized());
      case ForegroundServiceMethod.start:
        _controller?.start();
      case ForegroundServiceMethod.dispose:
        _controller?.dispose();
        unawaited(sendEventDisposed());
      case ForegroundServiceMethod.startSessionEarly:
        unawaited(_controller?.startSessionEarly());
      case ForegroundServiceMethod.broadcastUserAdvanceFromPrelude:
        _controller?.broadcastUserAdvanceFromPrelude();
      case ForegroundServiceMethod.pause:
        _controller?.pause();
      case ForegroundServiceMethod.resume:
        _controller?.resume();
    }
  }

  // ------------------------------------------------------------------------
  // Make controller

  void _makeExternalOrchestratorController(dynamic json) {
    final isOnline = isOnlineStartupParamsForegroundService(json);
    if (isOnline) {
      // is already checked
      _makeExternalOrchestratorControllerOnline(json as Map<String, dynamic>);
    } else {
      // is already checked
      _makeExternalOrchestratorControllerOffline(json as Map<String, dynamic>);
    }
  }

  void _makeExternalOrchestratorControllerOffline(Map<String, dynamic> json) {
    final ForegroundServiceStartupParamsOffline data = deserializeStartupParamsOfflineForegroundService(json);
    _controller = ExternalOrchestratorOfflineController(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      callbackProcessNetworkTick: callbackProcessNetworkTick,
      sessionId: data.sessionId,
      broadcastState: data.broadcastState,
      sessionDuration: data.sessionDuration,
    );
  }

  void _makeExternalOrchestratorControllerOnline(Map<String, dynamic> json) {
    final ForegroundServiceStartupParamsOnline data = deserializeStartupParamsOnlineForegroundService(json);

    _controller = ExternalOrchestratorOnlineController(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetVoiceovers: callbackSetVoiceovers,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      callbackProcessNetworkTick: callbackProcessNetworkTick,
      environment: data.environment,
      broadcastId: data.broadcastId,
      sessionId: data.sessionId,
    );
  }

  // ------------------------------------------------------------------------
  // Process callbacks

  Future<void> callbackSetBroadcastState(SessionBroadcastState state) async {
    await sendMessageToMain(serializeSetBroadcastState(state));
  }

  Future<void> callbackSetVoiceovers(List<VoiceoverStage> voiceovers) async {
    await sendMessageToMain(serializeSetVoiceovers(voiceovers));
  }

  Future<void> callbackSetSessionDuration(Duration duration) async {
    await sendMessageToMain(serializeSetSessionDuration(duration));
  }

  Future<void> callbackSetPlaybackTime(Duration currentPlayTime) async {
    await sendMessageToMain(serializeSetPlaybackTime(currentPlayTime));
  }

  Future<void> callbackProcessNetworkTick(NetworkTick tick) async {
    await sendMessageToMain(serializeProcessNetworkTick(tick));
  }

  // ------------------------------------------------------------------------
  // Send events

  Future<void> sendEventDisposed() async {
    await sendMessageToMain(serializeEventDisposedForegroundService());
  }

  Future<void> sendEventInitialized() async {
    await sendMessageToMain(serializeEventInitializedForegroundService());
  }
}
