import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';
import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';
import 'package:wp_player/utils/data_check/is_json_list_of_dicts_or_null.dart';

class SessionScore {
  final String name;
  final EmotionalIntensity emotionalIntensity;
  final TriadOfAtmosphereColors atmosphereColors;
  final List<VoiceoverStage>? voiceovers;

  SessionScore({
    required this.name,
    required this.emotionalIntensity,
    required this.atmosphereColors,
    required List<VoiceoverStage>? voiceovers,
  }) : voiceovers = (voiceovers == null ? null : List.unmodifiable(voiceovers));

  static SessionScore? fromJson(Map<String, dynamic> json) {
    final dynamic voiceoversJsonUnchecked = json["voiceover"];
    final dynamic emotionalitiesJson = json["emotionalities"];
    final dynamic intensityJson = json["intensity"];
    final dynamic name = json["name"];

    if (!isJsonListOfDictsOrNull(voiceoversJsonUnchecked) ||
        emotionalitiesJson is! Map<String, dynamic>? ||
        intensityJson is! String? ||
        name is! String) {
      return null;
    }

    late final EmotionalIntensity emotionalIntensity;
    if (intensityJson == null) {
      emotionalIntensity = EmotionalIntensity.none;
    } else {
      emotionalIntensity = EmotionalIntensity.fromString(intensityJson) ?? EmotionalIntensity.none;
    }

    late final TriadOfAtmosphereColors atmosphereColors;
    if (emotionalitiesJson == null) {
      atmosphereColors = (
        first: AtmosphereColor.silence,
        second: AtmosphereColor.silence,
        third: AtmosphereColor.silence,
      );
    } else {
      atmosphereColors =
          _parseAtmosphereColors(emotionalitiesJson) ??
          (first: AtmosphereColor.silence, second: AtmosphereColor.silence, third: AtmosphereColor.silence);
    }

    // ---
    // type is already checked
    final List<Map<String, dynamic>>? voiceoversJson =
        voiceoversJsonUnchecked == null ? null : (voiceoversJsonUnchecked as List).cast<Map<String, dynamic>>();

    late List<VoiceoverStage>? voiceovers;
    if (voiceoversJson == null) {
      voiceovers = null;
    } else {
      final List<VoiceoverStage?> temp = voiceoversJson.map(VoiceoverStage.fromJson).toList();
      if (temp.contains(null)) return null;
      voiceovers = temp.cast<VoiceoverStage>();
    }

    return SessionScore(
      name: name,
      emotionalIntensity: emotionalIntensity,
      atmosphereColors: atmosphereColors,
      voiceovers: voiceovers,
    );
  }
}

TriadOfAtmosphereColors? _parseAtmosphereColors(Map<String, dynamic> json) {
  final firstJson = json['primary'];
  final secondJson = json['secondary'];
  final thirdJson = json['tertiary'];

  final first = AtmosphereColor.fromString(firstJson) ?? AtmosphereColor.silence;
  final second = AtmosphereColor.fromString(secondJson) ?? AtmosphereColor.silence;
  final third = AtmosphereColor.fromString(thirdJson) ?? AtmosphereColor.silence;

  return (first: first, second: second, third: third);
}
