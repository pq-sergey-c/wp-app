import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wp_player/services/client_id/client_id.service.dart';
import 'package:wp_player/services/player/types/link_session_info.player.dart';
import 'package:wp_player/services/player/types/session.player.dart';
import 'package:wp_player/utils/logger/logger.dart';

Future<Session?> fetchSession(final LinkSessionInfo linkSessionInfo) async {
  final Uri orchestrator = linkSessionInfo.externalOrchestratorEnv.orchestratorUri;
  final String anonymousToken = ClientId().clientIdentifier;

  // Fetch website session
  final sessionInfoUrl = orchestrator.replace(
    pathSegments: [...orchestrator.pathSegments, 'sessions', 'my', linkSessionInfo.broadcastId],
  );
  
  final sessionInfoResponse = await http.get(sessionInfoUrl, headers: {'Authorization': 'anonymous $anonymousToken'});

  if (sessionInfoResponse.statusCode != 200) {
    logConsole.e('Failed to fetch session info');
    return null;
  }

  final session = _parseSessionInformation(sessionInfoResponse.body);
  if (session == null) return null;

  final sessionId = session.sessionId;
  final duration = session.duration;
  final endTime = session.endTime;

  // Fetch session details
  final sessionUri = orchestrator.replace(pathSegments: [...orchestrator.pathSegments, 'sessions', sessionId]);
  final sessionDetailsResponse = await http.get(sessionUri, headers: {'Authorization': 'anonymous $anonymousToken'});

  if (sessionDetailsResponse.statusCode != 200) {
    logConsole.e('Failed to fetch full session data (by sessionId)');
    return null;
  }

  // Parse result
  final result = Session.fromJson(jsonDecode(sessionDetailsResponse.body), duration: duration, endTime: endTime);
  if (result == null) {
    logConsole.f("Failed to parse Session - recheck correctness of mirroring of client and server");
    return null;
  }

  return result;
}

({Duration duration, DateTime? endTime, String sessionId})? _parseSessionInformation(String response) {
  final sessionInfoJson = jsonDecode(response);
  if (sessionInfoJson is! Map<String, dynamic>) {
    logConsole.e('Session info response is not a Map<String, dynamic>: $sessionInfoJson');
    return null;
  }
  final sessionId = sessionInfoJson['id'];
  if (sessionId is! String) {
    logConsole.e('No id in response to fetch of session info');
    return null;
  }

  final durationMilliseconds = sessionInfoJson['duration'] ?? 0;
  final endTimeMilliseconds = sessionInfoJson['endTime'];
  if (durationMilliseconds is! num || endTimeMilliseconds is! num?) {
    logConsole.e('Unexpected json structure on fetch of session info (duration or endTime)');
    return null;
  }

  final duration = Duration(milliseconds: durationMilliseconds.toInt());
  final endTime = endTimeMilliseconds != null ? DateTime.fromMillisecondsSinceEpoch(endTimeMilliseconds.toInt()) : null;

  return (duration: duration, endTime: endTime, sessionId: sessionId);
}
