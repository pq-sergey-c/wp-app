import 'package:wp_player/services/external_orchestrator/types/enums/network_session_state.external_orchestrator.dart';

class NetworkTick {
  final NetworkSessionState sessionState;
  final Duration timeUntilStart;
  final Duration effectiveTime;
  final Duration absoluteTime;
  final Duration timeSinceInit;
  final Duration sessionDuration;

  const NetworkTick({
    required this.sessionState,
    required this.timeUntilStart,
    required this.effectiveTime,
    required this.absoluteTime,
    required this.timeSinceInit,
    required this.sessionDuration,
  });

  const NetworkTick.sessionStateOnly({required this.sessionState})
    : timeUntilStart = Duration.zero,
      effectiveTime = Duration.zero,
      absoluteTime = Duration.zero,
      timeSinceInit = Duration.zero,
      sessionDuration = Duration.zero;

  static NetworkTick? fromJson(Map<String, dynamic> json) {
    final sessionStateJson = json["sessionState"];
    final timeUntilStartMillisecondsJson = json["timeUntilStart"];
    final effectiveTimeMillisecondsJson = json["effectiveTime"];
    final absoluteTimeMillisecondsJson = json["absoluteTime"];
    final timeSinceInitMillisecondsJson = json["timeSinceInit"];
    final sessionDurationMillisecondsJson = json["sessionDuration"];

    if (sessionStateJson is! String ||
        timeUntilStartMillisecondsJson is! num ||
        effectiveTimeMillisecondsJson is! num ||
        absoluteTimeMillisecondsJson is! num ||
        timeSinceInitMillisecondsJson is! num ||
        sessionDurationMillisecondsJson is! num) {
      return null;
    }

    final sessionState = NetworkSessionState.fromString(sessionStateJson);
    if (sessionState == null) return null;

    final timeUntilStart = Duration(milliseconds: timeUntilStartMillisecondsJson.toInt());
    final effectiveTime = Duration(milliseconds: effectiveTimeMillisecondsJson.toInt());
    final absoluteTime = Duration(milliseconds: absoluteTimeMillisecondsJson.toInt());
    final timeSinceInit = Duration(milliseconds: timeSinceInitMillisecondsJson.toInt());
    final sessionDuration = Duration(milliseconds: sessionDurationMillisecondsJson.toInt());

    return NetworkTick(
      sessionState: sessionState,
      timeUntilStart: timeUntilStart,
      effectiveTime: effectiveTime,
      absoluteTime: absoluteTime,
      timeSinceInit: timeSinceInit,
      sessionDuration: sessionDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionState': sessionState.value,
      'timeUntilStart': timeUntilStart.inMilliseconds,
      'effectiveTime': effectiveTime.inMilliseconds,
      'absoluteTime': absoluteTime.inMilliseconds,
      'timeSinceInit': timeSinceInit.inMilliseconds,
      'sessionDuration': sessionDuration.inMilliseconds,
    };
  }
}
