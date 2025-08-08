import 'package:wp_player/types/session/session_render_type.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_score.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_variable_inputs.player.dart';

class Session {
  final String id;
  final SessionRenderType renderType;
  final SessionScore score;
  final SessionVariableInputs? variableInputs;
  final bool canClientStartEarly;
  final SessionBroadcastState? broadcastState;
  final Duration duration;
  final DateTime? endTime;

  const Session({
    required this.id,
    required this.renderType,
    required this.score,
    required this.variableInputs,
    required this.canClientStartEarly,
    required this.broadcastState,
    required this.duration,
    required this.endTime,
  });

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

    return Session(
      id: id,
      renderType: renderType,
      score: score,
      variableInputs: variableInputs,
      canClientStartEarly: canClientStartEarly,
      broadcastState: broadcastState,
      duration: duration,
      endTime: endTime,
    );
  }
}
