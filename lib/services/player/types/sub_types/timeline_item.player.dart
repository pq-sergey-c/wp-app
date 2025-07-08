class TimelineItem {
  final String sessionId;
  final Duration digitalSignalProcessingOffset;

  const TimelineItem({required this.sessionId, required this.digitalSignalProcessingOffset});

  static TimelineItem? fromJson(Map<String, dynamic> json) {
    final dynamic sessionId = json["sessionId"];
    final dynamic digitalSignalProcessingOffsetMilliseconds = json["dspOffset"];

    if (sessionId is! String || digitalSignalProcessingOffsetMilliseconds is! num) {
      return null;
    }

    return TimelineItem(
      sessionId: sessionId,
      digitalSignalProcessingOffset: Duration(milliseconds: digitalSignalProcessingOffsetMilliseconds.toInt()),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'sessionId': sessionId,
      'dspOffset': digitalSignalProcessingOffset.inMilliseconds,
    };

    return json;
  }

  TimelineItem copy() =>
      TimelineItem(sessionId: sessionId, digitalSignalProcessingOffset: digitalSignalProcessingOffset);
}
