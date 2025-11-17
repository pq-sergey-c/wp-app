import 'dart:async';

import 'package:wp_player/services/external_orchestrator/orchestrator_network/controller.external_orchestrator.interface.dart';
import 'package:wp_player/services/external_orchestrator/types/callbacks.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/network_session_state.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/timeline_item.player.dart';

class ExternalOrchestratorOfflineController implements IExternalOrchestratorController {
  ExternalOrchestratorOfflineController({
    required CallbackSetBroadcastState callbackSetBroadcastState,
    required CallbackSetSessionDuration callbackSetSessionDuration,
    required CallbackSetPlaybackTime callbackSetPlaybackTime,
    required CallbackProcessNetworkTick callbackProcessNetworkTick,
    required String sessionId,
    required SessionBroadcastState? broadcastState,
    required Duration sessionDuration,
  }) : _callbackSetSessionDuration = callbackSetSessionDuration,
       _callbackSetBroadcastState = callbackSetBroadcastState,
       _callbackSetPlaybackTime = callbackSetPlaybackTime,
       _callbackProcessNetworkTick = callbackProcessNetworkTick,
       _broadcastState = broadcastState?.copy(),
       _sessionDuration = sessionDuration,
       _networkSessionState = NetworkSessionState.pause,
       _playedTime = Duration.zero,
       _startedPlayingAt = null {
    if (_broadcastState != null && _broadcastState!.timeline.isEmpty) {
      _broadcastState = SessionBroadcastState(
        startSessionTimers: _broadcastState!.startSessionTimers,
        timeline: List.unmodifiable([TimelineItem(sessionId: sessionId, digitalSignalProcessingOffset: Duration.zero)]),
      );
    }
  }

  final Duration _sessionDuration;

  final CallbackSetBroadcastState _callbackSetBroadcastState;
  final CallbackSetSessionDuration _callbackSetSessionDuration;
  final CallbackSetPlaybackTime _callbackSetPlaybackTime;
  final CallbackProcessNetworkTick _callbackProcessNetworkTick;

  NetworkSessionState _networkSessionState;

  SessionBroadcastState? _broadcastState;
  Timer? _periodicTickTimer;

  Duration _playedTime;
  DateTime? _startedPlayingAt;

  // -------------------------------------------------------------------------------------------

  @override
  void start() {
    if (_periodicTickTimer != null) {
      dispose();
    }

    if (_broadcastState != null) _callbackSetBroadcastState(_broadcastState!);
    _callbackSetSessionDuration(_sessionDuration);

    _periodicTickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _emulateNetworkTick());
  }

  @override
  void dispose() {
    _periodicTickTimer?.cancel();
    _periodicTickTimer = null;
  }

  @override
  Future<void> startSessionEarly() async {
    // do nothing
    return;
  }

  @override
  void broadcastUserAdvanceFromPrelude() {
    // do nothing
    return;
  }

  @override
  void pause() {
    if (_networkSessionState == NetworkSessionState.ended) return;

    _networkSessionState = NetworkSessionState.pause;

    if (_startedPlayingAt == null) return;

    _playedTime += DateTime.now().difference(_startedPlayingAt!);
    _startedPlayingAt = null;
  }

  @override
  void resume() {
    if (_networkSessionState == NetworkSessionState.ended) return;

    _networkSessionState = NetworkSessionState.mainPhase;
    _startedPlayingAt = DateTime.now();
  }

  // -------------------------------------------------------------------------------------------

  // TODO: here and in online service constant changing of Phase seems badly -> maybe check before changing current phase+currentPlayedTime
  // (yet maybe this constant changing could be ignored)
  // also we can use seekToTime in phase instead of changePhaseTo, there is also timeInPhase getter in nativeLibrary
  void _emulateNetworkTick() {
    final elapsedPlaybackTime =
        _startedPlayingAt == null ? Duration.zero : DateTime.now().difference(_startedPlayingAt!);

    final currentPlayedTime = _playedTime + elapsedPlaybackTime;

    final networkSessionState =
        currentPlayedTime >= _sessionDuration ? NetworkSessionState.ended : _networkSessionState;

    _callbackSetPlaybackTime(currentPlayedTime);
    _updateNativePlayerBasedOnNetworkTick(networkSessionState, currentPlayedTime);
  }

  void _updateNativePlayerBasedOnNetworkTick(NetworkSessionState networkSessionState, Duration currentPlayedTime) {
    switch (networkSessionState) {
      case NetworkSessionState.pause:
        _startedPlayingAt = null;
      case NetworkSessionState.mainPhase:
        _playedTime = currentPlayedTime;
        _startedPlayingAt = DateTime.now();
      case NetworkSessionState.ended:
        _playedTime = currentPlayedTime;
        _startedPlayingAt = null;
      case _:
        throw StateError("Invalid networkSessionState ${networkSessionState.value} for offline external orchestrator");
    }

    _callbackProcessNetworkTick(
      NetworkTick(
        sessionState: networkSessionState,
        timeUntilStart: Duration.zero,
        effectiveTime: currentPlayedTime,
        absoluteTime: Duration.zero,
        sessionDuration: Duration.zero,
      ),
    );
  }
}
