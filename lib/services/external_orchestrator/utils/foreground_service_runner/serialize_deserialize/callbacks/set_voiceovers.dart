import 'package:wp_player/services/external_orchestrator/types/enums/foreground_service_callback.external_orchestrator.dart';
import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';
import 'package:wp_player/utils/data_check/is_json_list_of_dicts.dart';

Map<String, dynamic> serializeSetVoiceovers(List<VoiceoverStage> voiceovers) => {
  'type': ForegroundServiceCallback.setVoiceovers.value,
  'data': voiceovers.map((v) => v.toJson()).toList(),
};

List<VoiceoverStage> deserializeSetVoiceovers(Map<String, dynamic> json) {
  final voiceoversListJsonUnchecked = json["data"];
  if (!isJsonListOfDicts(voiceoversListJsonUnchecked)) {
    throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetVoiceovers");
  }
  // type is already checked
  final voiceoversListJson = (voiceoversListJsonUnchecked as List<dynamic>).cast<Map<String, dynamic>>();

  final result = List<VoiceoverStage?>.filled(voiceoversListJson.length, null, growable: false);

  for (int i = 0; i < voiceoversListJson.length; i++) {
    final parsed = VoiceoverStage.fromJson(voiceoversListJson[i]);
    if (parsed == null) {
      throw StateError("Incoherent state in foreground service serialize/deserialize: deserializeSetVoiceovers");
    }
    result[i] = parsed;
  }

  return result.cast<VoiceoverStage>();
}
