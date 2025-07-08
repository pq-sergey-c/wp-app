import 'package:wp_player/services/player/types/sub_types/voiceover_stage_timing.player.dart';

class VoiceoverStage {
  final String stage;
  final VoiceoverStageTiming timing;
  final double? volume;
  final double? musicGain;
  final Duration duration;
  final String fileNameWithoutExtension;
  final String description;
  final String customVoiceoverId;

  const VoiceoverStage({
    required this.stage,
    required this.timing,
    required this.volume,
    required this.musicGain,
    required this.duration,
    required this.fileNameWithoutExtension,
    required this.description,
    required this.customVoiceoverId,
  });

  static VoiceoverStage? fromJson(Map<String, dynamic> json) {
    final dynamic stage = json["stage"];
    final dynamic timingJson = json["timing"];
    final dynamic volume = json["volume"];
    final dynamic musicGain = json["musicGain"];
    final dynamic durationMilliseconds = json["duration"];
    final dynamic fileNameWithoutExtension = json["fileNameWithoutExtension"];
    final dynamic description = json["description"];
    final dynamic customVoiceoverId = json["custom_voiceover_id"];

    if (stage is! String ||
        timingJson is! Map<String, dynamic> ||
        volume is! num? ||
        musicGain is! num? ||
        durationMilliseconds is! num ||
        fileNameWithoutExtension is! String ||
        description is! String ||
        customVoiceoverId is! String) {
      return null;
    }

    final VoiceoverStageTiming? timing = VoiceoverStageTiming.fromJson(timingJson);
    if (timing == null) return null;

    return VoiceoverStage(
      stage: stage,
      timing: timing,
      volume: volume?.toDouble(),
      musicGain: musicGain?.toDouble(),
      duration: Duration(milliseconds: durationMilliseconds.toInt()),
      fileNameWithoutExtension: fileNameWithoutExtension,
      description: description,
      customVoiceoverId: customVoiceoverId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'timing': timing.toJson(),
      'volume': volume,
      'musicGain': musicGain,
      'duration': duration.inMilliseconds,
      'fileNameWithoutExtension': fileNameWithoutExtension,
      'description': description,
      'custom_voiceover_id': customVoiceoverId,
    };
  }
}
