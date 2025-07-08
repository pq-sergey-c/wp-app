import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';
import 'package:wp_player/utils/data_check/is_json_list_of_dicts.dart';

List<VoiceoverStage>? parseSessionEvent(dynamic json) {
  if (json is! Map<String, dynamic>) return null;

  final event = json["event"];
  if (event is! Map<String, dynamic>) return null;

  final revisedScore = event["revisedScore"];
  if (revisedScore is! Map<String, dynamic>) return null;

  final voiceoversListJsonUnchecked = revisedScore["voiceover"];
  if (!isJsonListOfDicts(voiceoversListJsonUnchecked)) return null;
  // type is already checked
  final voiceoversListJson = (voiceoversListJsonUnchecked as List<dynamic>).cast<Map<String, dynamic>>();

  final result = List<VoiceoverStage?>.filled(voiceoversListJson.length, null, growable: false);

  for (int i = 0; i < voiceoversListJson.length; i++) {
    final parsed = VoiceoverStage.fromJson(voiceoversListJson[i]);
    if (parsed == null) return null;
    result[i] = parsed;
  }

  return result.cast<VoiceoverStage>();
}
