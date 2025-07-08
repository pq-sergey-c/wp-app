class VoiceoverStageTiming {
  final Duration from;
  final Duration to;

  const VoiceoverStageTiming({required this.from, required this.to});

  static VoiceoverStageTiming? fromJson(Map<String, dynamic> json) {
    final dynamic fromSeconds = json["from"];
    final dynamic toSeconds = json["to"];

    if (fromSeconds is! num || toSeconds is! num) {
      return null;
    }

    return VoiceoverStageTiming(from: Duration(seconds: fromSeconds.toInt()), to: Duration(seconds: toSeconds.toInt()));
  }

  Map<String, dynamic> toJson() {
    return {'from': from.inSeconds, 'to': to.inSeconds};
  }
}
