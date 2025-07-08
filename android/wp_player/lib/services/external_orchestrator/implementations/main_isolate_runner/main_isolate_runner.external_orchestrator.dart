import 'package:wp_player/services/external_orchestrator/external_orchestrator.service.interface.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/controller.external_orchestrator.interface.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/offline_controller/offline_controller.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/online_controller/online_controller.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/callbacks.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/network_session_state.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/player.native_lib/player.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player/player.service.dart';
import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';

class ExternalOrchestratorRunnerMainIsolate implements IExternalOrchestrator {
  ExternalOrchestratorRunnerMainIsolate._internal(this._controller);
  final IExternalOrchestratorController _controller;

  // -------------------------------------------------------------------------------------------

  factory ExternalOrchestratorRunnerMainIsolate.online({
    required CallbackSetBroadcastState callbackSetBroadcastState,
    required CallbackSetVoiceovers callbackSetVoiceovers,
    required CallbackSetSessionDuration callbackSetSessionDuration,
    required CallbackSetPlaybackTime callbackSetPlaybackTime,
    required ExternalOrchestratorEnvironment environment,
    required String broadcastId,
    required String sessionId,
  }) {
    final controller = ExternalOrchestratorOnlineController(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetVoiceovers: callbackSetVoiceovers,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      callbackProcessNetworkTick: _updateNativePlayerBasedOnNetworkTick,
      environment: environment,
      broadcastId: broadcastId,
      sessionId: sessionId,
    );
    return ExternalOrchestratorRunnerMainIsolate._internal(controller);
  }

  factory ExternalOrchestratorRunnerMainIsolate.offline({
    required CallbackSetBroadcastState callbackSetBroadcastState,
    required CallbackSetSessionDuration callbackSetSessionDuration,
    required CallbackSetPlaybackTime callbackSetPlaybackTime,
    required String sessionId,
    required SessionBroadcastState? broadcastState,
    required Duration sessionDuration,
  }) {
    final controller = ExternalOrchestratorOfflineController(
      callbackSetBroadcastState: callbackSetBroadcastState,
      callbackSetSessionDuration: callbackSetSessionDuration,
      callbackSetPlaybackTime: callbackSetPlaybackTime,
      callbackProcessNetworkTick: _updateNativePlayerBasedOnNetworkTick,
      sessionId: sessionId,
      broadcastState: broadcastState,
      sessionDuration: sessionDuration,
    );
    return ExternalOrchestratorRunnerMainIsolate._internal(controller);
  }

  // -------------------------------------------------------------------------------------------

  @override
  Future<void> start() async => _controller.start();

  @override
  Future<void> dispose() async => _controller.dispose();

  @override
  Future<void> startSessionEarly() async => await _controller.startSessionEarly();

  @override
  void broadcastUserAdvanceFromPrelude() => _controller.broadcastUserAdvanceFromPrelude();

  @override
  void pause() => _controller.pause();

  @override
  void resume() => _controller.resume();

  // -------------------------------------------------------------------------------------------

  static void _updateNativePlayerBasedOnNetworkTick(final NetworkTick tick) {
    final isConnectionInterrupted = PlayerService().isConnectionInterruptedListenable?.value ?? true;
    if (isConnectionInterrupted && tick.sessionState != NetworkSessionState.connectionEstablished) {
      return;
    }

    switch (tick.sessionState) {
      case NetworkSessionState.pause:
        NativeLibraryPlayer().stop();
      case NetworkSessionState.prelude:
        NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhasePre, at: tick.timeSinceInit);
        NativeLibraryPlayer().start();
      case NetworkSessionState.mainPhase:
        NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhaseSession, at: tick.effectiveTime);
        NativeLibraryPlayer().start();
      case NetworkSessionState.postlude:
        NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhasePost, at: Duration.zero);
        NativeLibraryPlayer().start();
      case NetworkSessionState.ended:
        NativeLibraryPlayer().stop();
      case NetworkSessionState.planned:
        // do nothing
        break;
      case NetworkSessionState.connectionInterrupted:
        PlayerService().reportConnectionIssue();
        NativeLibraryPlayer().stop();
      case NetworkSessionState.connectionEstablished:
        PlayerService().reportConnectionRestored();
    }
  }
}
