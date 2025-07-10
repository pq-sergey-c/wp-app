import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';

abstract class _IForegroundServiceStartupParamsBase {
  abstract final bool isOnline;
  abstract final String sessionName;
  abstract final String artist;
  abstract final EmotionalIntensity emotionalIntensity;
  abstract final TriadOfAtmosphereColors atmosphereColors;
}
// -----------------------------------------------------------------------------------------------------------------
// Online

class ForegroundServiceStartupParamsOnline implements _IForegroundServiceStartupParamsBase {
  const ForegroundServiceStartupParamsOnline({
    required this.environment,
    required this.broadcastId,
    required this.sessionId,
    required this.sessionName,
    required this.artist,
    required this.emotionalIntensity,
    required this.atmosphereColors,
  }) : isOnline = true;

  @override
  final bool isOnline;
  final ExternalOrchestratorEnvironment environment;
  final String broadcastId;
  final String sessionId;
  @override
  final String sessionName;
  @override
  final String artist;
  @override
  final EmotionalIntensity emotionalIntensity;
  @override
  final TriadOfAtmosphereColors atmosphereColors;

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'environment': environment.value,
      'broadcastId': broadcastId,
      'sessionId': sessionId,
      'sessionName': sessionName,
      'artist': artist,
      'emotionalIntensity': emotionalIntensity.value,
      'atmosphereColors': _serializeTriadOfColors(atmosphereColors),
    };
  }

  static ForegroundServiceStartupParamsOnline? fromJson(Map<String, dynamic> json) {
    final isOnline = json['isOnline'];
    final environmentJson = json['environment'];
    final broadcastId = json['broadcastId'];
    final sessionId = json['sessionId'];
    final sessionName = json['sessionName'];
    final artist = json['artist'];
    final emotionalIntensityJson = json['emotionalIntensity'];
    final atmosphereColorsJson = json['atmosphereColors'];

    if (isOnline is! bool ||
        environmentJson is! String ||
        broadcastId is! String ||
        sessionId is! String ||
        sessionName is! String ||
        artist is! String ||
        emotionalIntensityJson is! String ||
        atmosphereColorsJson is! Map<String, dynamic>) {
      return null;
    }

    if (!isOnline) return null; // isn't online

    final environment = ExternalOrchestratorEnvironment.fromString(environmentJson);
    if (environment == null) return null;

    final emotionalIntensity = EmotionalIntensity.fromString(emotionalIntensityJson);
    if (emotionalIntensity == null) return null;

    final atmosphereColors = _deserializeTriadOfColors(atmosphereColorsJson);
    if (atmosphereColors == null) return null;

    return ForegroundServiceStartupParamsOnline(
      environment: environment,
      broadcastId: broadcastId,
      sessionId: sessionId,
      sessionName: sessionName,
      artist: artist,
      emotionalIntensity: emotionalIntensity,
      atmosphereColors: atmosphereColors,
    );
  }
}

// -----------------------------------------------------------------------------------------------------------------
// Offline

class ForegroundServiceStartupParamsOffline implements _IForegroundServiceStartupParamsBase {
  const ForegroundServiceStartupParamsOffline({
    required this.sessionId,
    required this.broadcastState,
    required this.sessionDuration,
    required this.sessionName,
    required this.artist,
    required this.emotionalIntensity,
    required this.atmosphereColors,
  }) : isOnline = false;

  @override
  final bool isOnline;
  final String sessionId;
  // broadcastStateJson == false means that broadcastState = null
  // it is used because serialized data is send to foreground task
  final SessionBroadcastState? broadcastState;
  final Duration sessionDuration;
  @override
  final String sessionName;
  @override
  final String artist;
  @override
  final EmotionalIntensity emotionalIntensity;
  @override
  final TriadOfAtmosphereColors atmosphereColors;

  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'sessionId': sessionId,
      'broadcastState': broadcastState == null ? false : broadcastState!.toJson(),
      'sessionDuration': sessionDuration.inMilliseconds,
      'sessionName': sessionName,
      'artist': artist,
      'emotionalIntensity': emotionalIntensity.value,
      'atmosphereColors': _serializeTriadOfColors(atmosphereColors),
    };
  }

  static ForegroundServiceStartupParamsOffline? fromJson(Map<String, dynamic> json) {
    final isOnline = json['isOnline'];
    final sessionId = json['sessionId'];
    final broadcastStateJson = json['broadcastState'];
    final sessionDurationMillisecondsJson = json['sessionDuration'];
    final sessionName = json['sessionName'];
    final artist = json['artist'];
    final emotionalIntensityJson = json['emotionalIntensity'];
    final atmosphereColorsJson = json['atmosphereColors'];

    if (isOnline is! bool ||
        sessionId is! String ||
        sessionDurationMillisecondsJson is! num ||
        sessionName is! String ||
        artist is! String ||
        emotionalIntensityJson is! String ||
        atmosphereColorsJson is! Map<String, dynamic>) {
      return null;
    }

    if (isOnline) return null; // is online

    SessionBroadcastState? broadcastState;
    if (broadcastStateJson is Map<String, dynamic>) {
      broadcastState = SessionBroadcastState.fromJson(broadcastStateJson);
      if (broadcastState == null) return null;
    } else if (broadcastStateJson != false) {
      // check comment about broadcastState
      return null;
    }

    final sessionDuration = Duration(milliseconds: sessionDurationMillisecondsJson.toInt());

    final emotionalIntensity = EmotionalIntensity.fromString(emotionalIntensityJson);
    if (emotionalIntensity == null) return null;

    final atmosphereColors = _deserializeTriadOfColors(atmosphereColorsJson);
    if (atmosphereColors == null) return null;

    return ForegroundServiceStartupParamsOffline(
      sessionId: sessionId,
      broadcastState: broadcastState,
      sessionDuration: sessionDuration,
      sessionName: sessionName,
      artist: artist,
      emotionalIntensity: emotionalIntensity,
      atmosphereColors: atmosphereColors,
    );
  }
}

// -----------------------------------------------------------------------------------------------------------------
// Utils

Map<String, dynamic> _serializeTriadOfColors(TriadOfAtmosphereColors colors) {
  return {"first": colors.first.value, "second": colors.second.value, "third": colors.third.value};
}

TriadOfAtmosphereColors? _deserializeTriadOfColors(Map<String, dynamic> json) {
  final firstJson = json["first"];
  final secondJson = json["second"];
  final thirdJson = json["third"];

  if (firstJson is! String || secondJson is! String || thirdJson is! String) {
    return null;
  }

  final first = AtmosphereColor.fromString(firstJson);
  final second = AtmosphereColor.fromString(secondJson);
  final third = AtmosphereColor.fromString(thirdJson);

  if (first == null || second == null || third == null) return null;

  return (first: first, second: second, third: third);
}
