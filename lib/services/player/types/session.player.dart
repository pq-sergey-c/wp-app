import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_score.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_variable_inputs.player.dart';
import 'package:wp_player/types/session/session_render_type/session_render_type.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class Session {
  final String id;
  final SessionRenderType renderType;
  final SessionScore score;
  final SessionVariableInputs? variableInputs;
  final bool canClientStartEarly;
  final SessionBroadcastState? broadcastState;
  final Duration duration;
  final DateTime? endTime;
  final String sessionName;

  const Session({
    required this.id,
    required this.renderType,
    required this.score,
    required this.variableInputs,
    required this.canClientStartEarly,
    required this.broadcastState,
    required this.duration,
    required this.endTime,
    required this.sessionName,
  });

  /// Safely calculates session name with fallback logic matching iOS:
  /// variableInputs.name -> score.name -> "--"
  static String _calculateSessionName({
    required SessionVariableInputs? variableInputs,
    required SessionScore score,
  }) {
    try {
      final variableInputsName = variableInputs?.name?.trim();
      final scoreName = score.name.trim();
      
      if (variableInputsName != null && variableInputsName.isNotEmpty) {
        return variableInputsName;
      } else if (scoreName.isNotEmpty) {
        return scoreName;
      } else {
        return "--";
      }
    } catch (e) {
      return "--";
    }
  }

  /// Returns Uri only when both [userRole] and [renderType] allows to have such url
  Uri? getProviderControlUri(UserRole userRole, ExternalOrchestratorEnvironment environment) {
    if (userRole != UserRole.provider || renderType != SessionRenderType.predictiveComposed) return null;
    final webAppUri = environment.webAppBaseUri;
    return webAppUri.replace(pathSegments: [...webAppUri.pathSegments, 'session', id]);
  }

  static Session? fromJson(Map<String, dynamic> json, {required Duration duration, DateTime? endTime}) {
    final dynamic id = json["id"];
    final dynamic renderTypeString = json["renderType"];
    final dynamic scoreJson = json["score"];
    final dynamic variableInputsJson = json["variableInputs"];
    final dynamic canClientStartEarly = json["canClientStartEarly"];
    final dynamic broadcastStateJson = json["broadcastState"];

    // json type check
    if (id is! String ||
        renderTypeString is! String ||
        scoreJson is! Map<String, dynamic> ||
        variableInputsJson is! Map<String, dynamic>? ||
        canClientStartEarly is! bool ||
        broadcastStateJson is! Map<String, dynamic>?) {
      return null;
    }

    // additional parse
    final SessionRenderType? renderType = SessionRenderType.fromString(renderTypeString);
    if (renderType == null) return null;

    final SessionScore? score = SessionScore.fromJson(scoreJson);
    if (score == null) return null;

    late SessionVariableInputs? variableInputs;
    if (variableInputsJson == null) {
      variableInputs = null;
    } else {
      final SessionVariableInputs? temp = SessionVariableInputs.fromJson(variableInputsJson);
      if (temp == null) return null;
      variableInputs = temp;
    }

    late SessionBroadcastState? broadcastState;
    if (broadcastStateJson == null) {
      broadcastState = null;
    } else {
      final SessionBroadcastState? temp = SessionBroadcastState.fromJson(broadcastStateJson);
      if (temp == null) return null;
      broadcastState = temp;
    }

    final String sessionName = _calculateSessionName(
      variableInputs: variableInputs,
      score: score,
    );

    return Session(
      id: id,
      renderType: renderType,
      score: score,
      variableInputs: variableInputs,
      canClientStartEarly: canClientStartEarly,
      broadcastState: broadcastState,
      duration: duration,
      endTime: endTime,
      sessionName: sessionName,
    );
  }
}
