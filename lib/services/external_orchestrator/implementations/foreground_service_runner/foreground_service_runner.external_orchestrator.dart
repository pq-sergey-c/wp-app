import 'dart:async';
import 'dart:convert';
import 'package:mutex/mutex.dart';
import 'package:wp_player/services/external_orchestrator/external_orchestrator.service.interface.dart';
import 'package:wp_player/services/external_orchestrator/implementations/helpers/handle_player_from_network_tick.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/callbacks.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_method.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/foreground_service_startup_params.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/log.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/process_network_tick.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_broadcast_state.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_playback_time.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_session_duration.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/callbacks/set_voiceovers.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/methods/event_methods.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/methods/startup.dart';
import 'package:wp_player/services/external_orchestrator/utils/foreground_service_runner/serialize_deserialize/validate_message_and_get_type.dart';
import 'package:wp_player/services/foreground_kotlin/foreground_kotlin.service.dart';
import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_score.player.dart';
import 'package:wp_player/utils/logger/logger.dart';

class ExternalOrchestratorRunnerForegroundService implements IExternalOrchestrator {
  static final Mutex _initMutex = Mutex();

  // ---

  final Map<String, dynamic> _startData;
  bool _initWasAlreadyCalled = false;

  final CallbackSetBroadcastState _callbackSetBroadcastState;
  final CallbackSetVoiceovers _callbackSetVoiceovers;
  final CallbackSetSessionDuration _callbackSetSessionDuration;
  final CallbackSetPlaybackTime _callbackSetPlaybackTime;

  // ----------------------------------------------------------------------------------
  // Callbacks from foreground service

  Future<void> _onReceiveMessageFromForegroundService(String jsonString) async {
    final jsonRaw = jsonDecode(jsonString);

    final callbackTypeString = foregroundServiceValidateMessageAndGetType(jsonRaw);
    final json = jsonRaw as Map<String, dynamic>; // already validated

    final callbackType = ForegroundServiceCallback.fromString(callbackTypeString);
    if (callbackType == null) {
      logConsole.f("Unknown callback type in External orchestrator (Foreground service): $callbackTypeString");
      return;
    }

    switch (callbackType) {
      case ForegroundServiceCallback.setBroadcastState:
        _handleSetBroadcastState(json);
      case ForegroundServiceCallback.setSessionDuration:
        _handleSetSessionDuration(json);
      case ForegroundServiceCallback.setPlaybackTime:
        _handleSetPlaybackTime(json);
      case ForegroundServiceCallback.setVoiceovers:
        _handleSetVoiceovers(json);
      case ForegroundServiceCallback.processNetworkTick:
        _handleProcessNetworkTick(json);
      case ForegroundServiceCallback.log:
        _handleLog(json);
      case ForegroundServiceCallback.disposed:
        await _processDisposedEvent();
      case ForegroundServiceCallback.initialized:
        _processInitializedEvent();
    }
  }

  void _handleLog(Map<String, dynamic> json) {
    logConsole.d("[Foreground service]: ${deserializeLogForegroundService(json)}");
  }

  void _handleSetBroadcastState(Map<String, dynamic> json) {
    _callbackSetBroadcastState(deserializeSetBroadcastState(json));
  }

  void _handleSetSessionDuration(Map<String, dynamic> json) {
    _callbackSetSessionDuration(deserializeSetSessionDuration(json));
  }

  void _handleSetPlaybackTime(Map<String, dynamic> json) {
    _callbackSetPlaybackTime(deserializeSetPlaybackTime(json));
  }

  void _handleSetVoiceovers(Map<String, dynamic> json) {
    _callbackSetVoiceovers(deserializeSetVoiceovers(json));
  }

  void _handleProcessNetworkTick(Map<String, dynamic> json) {
    final tick = deserializeProcessNetworkTick(json);
    externalOrchestratorHandlePlayerStateFromTick(tick);
  }

  Future<void> _processDisposedEvent() async {
    if (!await ForegroundKotlinService().doesForegroundExist()) return;
    ForegroundKotlinService().setMessageHandler(null);
    await ForegroundKotlinService().dispose();
  }

  void _processInitializedEvent() {
    _initMutex.release();
  }

  // ----------------------------------------------------------------------------------
  // Call foreground methods

  @override
  Future<void> start() async {
    await _startService();

    // ensure is initialized
    await _initMutex.acquire();
    _initMutex.release();

    await ForegroundKotlinService().sendMessageJSON(
      serializeEventMethodsForegroundService(ForegroundServiceMethod.start),
    );
  }

  @override
  Future<void> startSessionEarly() async {
    await ForegroundKotlinService().sendMessageJSON(
      serializeEventMethodsForegroundService(ForegroundServiceMethod.startSessionEarly),
    );
  }

  @override
  void broadcastUserAdvanceFromPrelude() {
    unawaited(
      ForegroundKotlinService().sendMessageJSON(
        serializeEventMethodsForegroundService(ForegroundServiceMethod.broadcastUserAdvanceFromPrelude),
      ),
    );
  }

  @override
  void pause() {
    unawaited(
      ForegroundKotlinService().sendMessageJSON(serializeEventMethodsForegroundService(ForegroundServiceMethod.pause)),
    );
  }

  @override
  void resume() {
    unawaited(
      ForegroundKotlinService().sendMessageJSON(serializeEventMethodsForegroundService(ForegroundServiceMethod.resume)),
    );
  }

  @override
  Future<void> dispose() async {
    await ForegroundKotlinService().sendMessageJSON(
      serializeEventMethodsForegroundService(ForegroundServiceMethod.dispose),
    );
  }

  // ----------------------------------------------------------------------------------
  // Make foreground service - maybe make _initService be called only once

  Future<void> _startService() async {
    if (_initWasAlreadyCalled) return;
    _initWasAlreadyCalled = true;

    await ForegroundKotlinService().ensureStopped();
    await ForegroundKotlinService().start();
    ForegroundKotlinService().setMessageHandler(_onReceiveMessageFromForegroundService);
    await ForegroundKotlinService().sendMessageJSON(_startData);
    await _initMutex.acquire(); // released when got initialized callback from foreground service
  }

  // ----------------------------------------------------------------------------------

  ExternalOrchestratorRunnerForegroundService.offline({
    required CallbackSetBroadcastState callbackSetBroadcastState,
    required CallbackSetSessionDuration callbackSetSessionDuration,
    required CallbackSetPlaybackTime callbackSetPlaybackTime,
    required String sessionId,
    required SessionBroadcastState? broadcastState,
    required Duration sessionDuration,
    required SessionScore sessionScore,
    required String artist,
    required String sessionName,
  }) : _startData = serializeStartupParamsOfflineForegroundService(
         ForegroundServiceStartupParamsOffline(
           sessionId: sessionId,
           broadcastState: broadcastState,
           sessionDuration: sessionDuration,
           sessionName: sessionName,
           artist: artist,
           emotionalIntensity: sessionScore.emotionalIntensity,
           atmosphereColors: sessionScore.atmosphereColors,
         ),
       ),
       _callbackSetBroadcastState = callbackSetBroadcastState,
       _callbackSetPlaybackTime = callbackSetPlaybackTime,
       _callbackSetSessionDuration = callbackSetSessionDuration,
       _callbackSetVoiceovers = ((_) => {});

  ExternalOrchestratorRunnerForegroundService.online({
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
  }) : _startData = serializeStartupParamsOnlineForegroundService(
         ForegroundServiceStartupParamsOnline(
           environment: environment,
           broadcastId: broadcastId,
           sessionId: sessionId,
           sessionName: sessionName,
           artist: artist,
           emotionalIntensity: sessionScore.emotionalIntensity,
           atmosphereColors: sessionScore.atmosphereColors,
         ),
       ),
       _callbackSetBroadcastState = callbackSetBroadcastState,
       _callbackSetPlaybackTime = callbackSetPlaybackTime,
       _callbackSetSessionDuration = callbackSetSessionDuration,
       _callbackSetVoiceovers = callbackSetVoiceovers;
}
