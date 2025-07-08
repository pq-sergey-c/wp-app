// FIXME:   final DateTime? startSessionTimers; | in json parse it is viewed as milliseconds,
// check what is it on server side

// FIXME:   final List<TimelineItem> discarded | is unused in swift
// update in orchestrator offline if deemed to use

import 'package:wp_player/services/player/types/sub_types/timeline_item.player.dart';
import 'package:wp_player/utils/data_check/is_json_list_of_dicts.dart';

class SessionBroadcastState {
  final DateTime startSessionTimers;
  final List<TimelineItem> timeline;
  final List<TimelineItem> discarded; // is unused

  SessionBroadcastState({required this.startSessionTimers, required List<TimelineItem> timeline})
    : timeline = List.unmodifiable(timeline),
      discarded = List.unmodifiable([]);

  static SessionBroadcastState? fromJson(Map<String, dynamic> json) {
    final dynamic startSessionTimersMilliseconds = json["startSessionTimersTimestamp"];
    final dynamic timelineJsonUnchecked = json["timeline"];

    if (startSessionTimersMilliseconds is! num? || !isJsonListOfDicts(timelineJsonUnchecked)) {
      return null;
    }
    // type is already checked
    final List<Map<String, dynamic>> timelineJson =
        (timelineJsonUnchecked as List<dynamic>).cast<Map<String, dynamic>>();

    final startSessionTimers =
        startSessionTimersMilliseconds == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(startSessionTimersMilliseconds.toInt());

    final List<TimelineItem?> timeline = timelineJson.map(TimelineItem.fromJson).toList();
    if (timeline.contains(null)) return null;

    return SessionBroadcastState(startSessionTimers: startSessionTimers, timeline: timeline.cast<TimelineItem>());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'startSessionTimersTimestamp': startSessionTimers.millisecondsSinceEpoch,
      'timeline': timeline.map((item) => item.toJson()).toList(),
    };

    return json;
  }

  SessionBroadcastState copy() => SessionBroadcastState(
    startSessionTimers: startSessionTimers,
    timeline: timeline.map((item) => item.copy()).toList(),
  );
}
