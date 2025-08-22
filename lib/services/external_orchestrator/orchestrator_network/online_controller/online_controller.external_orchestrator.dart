import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:wp_player/services/client_id/client_id.service.dart';
import 'package:wp_player/services/external_orchestrator/orchestrator_network/controller.external_orchestrator.interface.dart';
import 'package:wp_player/services/external_orchestrator/types/callbacks.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/enums/network_session_state.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/utils/online_network/parse_session_event.dart';
import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/utils/logger/logger.dart';

class ExternalOrchestratorOnlineController implements IExternalOrchestratorController {
  ExternalOrchestratorOnlineController({
    required CallbackSetBroadcastState callbackSetBroadcastState,
    required CallbackSetVoiceovers callbackSetVoiceovers,
    required CallbackSetSessionDuration callbackSetSessionDuration,
    required CallbackSetPlaybackTime callbackSetPlaybackTime,
    required CallbackProcessNetworkTick callbackProcessNetworkTick,
    required ExternalOrchestratorEnvironment environment,
    required String broadcastId,
    required String sessionId,
  }) : _callbackSetSessionDuration = callbackSetSessionDuration,
       _callbackSetVoiceovers = callbackSetVoiceovers,
       _callbackSetBroadcastState = callbackSetBroadcastState,
       _callbackSetPlaybackTime = callbackSetPlaybackTime,
       _callbackProcessNetworkTick = callbackProcessNetworkTick,
       _environment = environment,
       _broadcastId = broadcastId,
       _sessionId = sessionId;

  final CallbackSetBroadcastState _callbackSetBroadcastState;
  final CallbackSetVoiceovers _callbackSetVoiceovers;
  final CallbackSetSessionDuration _callbackSetSessionDuration;
  final CallbackSetPlaybackTime _callbackSetPlaybackTime;
  final CallbackProcessNetworkTick _callbackProcessNetworkTick;

  Duration? _setSessionDuration;

  final ExternalOrchestratorEnvironment _environment;
  final String _broadcastId;
  final String _sessionId;

  socket_io.Socket? _socket;

  // -------------------------------------------------------------------------------------------

  @override
  void start() {
    _setSessionDuration = null;

    _makeSocket();
    _setupSessionEventsHandlingForSocket();
    _setupWorkloadEventsHandlingForSocket();

    _enforceSocketExists();
    _socket!.connect();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
  }

  @override
  Future<void> startSessionEarly() async {
    final orchestratorUri = _environment.orchestratorUri;
    final sessionInfoUrl = orchestratorUri.replace(
      pathSegments: [...orchestratorUri.pathSegments, 'sessions', 'my', _sessionId],
    );

    final anonymousToken = ClientId().clientIdentifier;

    await http.patch(
      sessionInfoUrl,
      headers: {"Content-Type": "application/json", "Authorization": "anonymous $anonymousToken"},
      body: jsonEncode({"scheduledStart": 1}),
    );
  }

  @override
  void broadcastUserAdvanceFromPrelude() {
    _socket?.emit("broadcastUserAdvanceFromPrelude", {"allowControl": true});
  }

  @override
  void pause() {
    _socket?.emit("controlRequest", {"type": "pause"});
  }

  @override
  void resume() {
    _socket?.emit("controlRequest", {"type": "resume"});
  }

  // -------------------------------------------------------------------------------------------

  void _enforceSocketExists() {
    if (_socket == null) {
      throw Exception("Incoherent state in External Orchestrator (online version): socket is absent");
    }
  }

  void _makeSocket() {
    final Uri orchestrator = _environment.orchestratorUri;
    final Uri socketUrl = orchestrator.replace(
      pathSegments: [...orchestrator.pathSegments, 'broadcastMetadata', _broadcastId],
    );

    final socketOptions =
        socket_io.OptionBuilder()
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(10000)
            .setPath('/socket.io/')
            .setTransports(['websocket'])
            .build();

    _socket = socket_io.io(socketUrl.toString(), socketOptions);
  }

  void _setupSessionEventsHandlingForSocket() {
    _enforceSocketExists();

    _socket!.onConnect((_) {
      logConsole.d('External orchestrator connected');
      _socket!.emit('setUser', {'type': 'anonymous', 'anonymousToken': ClientId().clientIdentifier});

      _callbackProcessNetworkTick(
        const NetworkTick.sessionStateOnly(sessionState: NetworkSessionState.connectionEstablished),
      );
    });

    _socket!.onDisconnect((reason) {
      logConsole.e('Socket disconnected: $reason');
      _callbackProcessNetworkTick(
        const NetworkTick.sessionStateOnly(sessionState: NetworkSessionState.connectionInterrupted),
      );
      unawaited(_tryToReconnect());
    });

    _socket!.onConnectError((error) {
      logConsole.e('Socket connection error: $error');
      _callbackProcessNetworkTick(
        const NetworkTick.sessionStateOnly(sessionState: NetworkSessionState.connectionInterrupted),
      );
      unawaited(_tryToReconnect());
    });

    _socket!.onError((error) {
      logConsole.e('External orchestrator got error: $error');
      _callbackProcessNetworkTick(
        const NetworkTick.sessionStateOnly(sessionState: NetworkSessionState.connectionInterrupted),
      );
      unawaited(_tryToReconnect());
    });
  }

  Future<void> _tryToReconnect() async {
    logConsole.d('Retrying after 3s...');
    await Future.delayed(const Duration(seconds: 3), () => _socket?.connect());
  }

  // -------------------------------------------------------------------------------------------

  void _setupWorkloadEventsHandlingForSocket() {
    _enforceSocketExists();

    _socket!.on("broadcastStateUpdate", (data) {
      if (data is! Map<String, dynamic>) return;

      final SessionBroadcastState? state = SessionBroadcastState.fromJson(data);
      if (state == null) {
        logConsole.f("External orchestrator failed to parse [broadcastStateUpdate] event, got: $data");
        return;
      }
      _callbackSetBroadcastState(state);
    });

    _socket!.on("sessionEvent", (data) {
      final voiceovers = parseSessionEvent(data);
      if (voiceovers == null) {
        logConsole.f("External orchestrator failed to parse [sessionEvent] event, got: $data");
        return;
      }
      _callbackSetVoiceovers(voiceovers);
    });

    _socket!.on("tick", (data) {
      if (data is! Map<String, dynamic>) return;

      final tick = NetworkTick.fromJson(data);
      if (tick == null) {
        logConsole.f("External orchestrator failed to parse [tick] event, got: $data");
        return;
      }

      _callbackProcessNetworkTick(tick);
      if (_setSessionDuration == null || _setSessionDuration != tick.sessionDuration) {
        _setSessionDuration = tick.sessionDuration;
        _callbackSetSessionDuration(_setSessionDuration!);
      }
      _callbackSetPlaybackTime(tick.effectiveTime);
    });
  }
}
