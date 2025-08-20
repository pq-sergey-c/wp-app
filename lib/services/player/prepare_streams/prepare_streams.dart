import 'package:wp_player/services/network/types/enums/network_url_prefixes.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';
import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/timeline_item.player.dart';
import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';

const _longTimeFromNow = Duration(days: 365);
const _streamFadeOutTime = Duration(seconds: 15);

const _freeVoiceoverDuration = Duration(minutes: 1);
const _freeVoiceoverEvery = Duration(minutes: 20);
const _freeVoiceoverStartOffset = Duration(seconds: 5);

List<WpPlayerStream> getStreams({
  required final SessionBroadcastState? latestBroadcastState,
  required final ExternalOrchestratorEnvironment orchestratorEnvironment,
  required final String broadcastId,
  required final String sessionId,
  required final List<VoiceoverStage>? voiceovers,
  required final Duration sessionDuration,
  required final bool hasFreeVoiceover,
}) {
  final prelude = _getPreludeStream();
  final session = _getSessionStreams(
    latestBroadcastState: latestBroadcastState,
    orchestratorEnvironment: orchestratorEnvironment,
    broadcastId: broadcastId,
    sessionId: sessionId,
  );
  final customVoiceover = _getCustomVoiceoverStreams(
    orchestratorEnvironment: orchestratorEnvironment,
    voiceovers: voiceovers,
  );
  final freeVoiceover = _getFreeVoiceoverStreams(
    orchestratorEnvironment: orchestratorEnvironment,
    sessionDuration: sessionDuration,
    hasFreeVoiceover: hasFreeVoiceover,
  );
  final postlude = _getPostludeStream();

  return [prelude, ...session, ...customVoiceover, ...freeVoiceover, postlude];
}

// --------------------------------------------------------------------------

WpPlayerStream _getPreludeStream() {
  const String url = "assets/audio/prelude_postlude_30m.mp3";
  final String prefixedUrl = NetworkUrlPrefixes.localFile.addPrefix(url);

  return WpPlayerStream(
    id: "prelude",
    phase: WpPhase.wpPhasePre,
    url: prefixedUrl,
    fromTime: Duration.zero,
    toTime: _longTimeFromNow,
    fadeOutTime: _streamFadeOutTime,
    loopContent: true,
    gain: 1.0,
    usesSidechain: false,
    sidechainGain: 0.0,
  );
}

WpPlayerStream _getPostludeStream() {
  const String url = "assets/audio/prelude_postlude_30m.mp3";
  final String prefixedUrl = NetworkUrlPrefixes.localFile.addPrefix(url);

  return WpPlayerStream(
    id: "prelude",
    phase: WpPhase.wpPhasePost,
    url: prefixedUrl,
    fromTime: Duration.zero,
    toTime: _longTimeFromNow,
    fadeOutTime: _streamFadeOutTime,
    loopContent: true,
    gain: 1.0,
    usesSidechain: false,
    sidechainGain: 0.0,
  );
}

List<WpPlayerStream> _getSessionStreams({
  required final SessionBroadcastState? latestBroadcastState,
  required final ExternalOrchestratorEnvironment orchestratorEnvironment,
  required final String broadcastId,
  required final String sessionId,
}) {
  final Uri orchestratorUrl = orchestratorEnvironment.streamUri;
  final Uri baseUrl = orchestratorUrl.replace(
    pathSegments: [...orchestratorUrl.pathSegments, 'streamdata', broadcastId],
  );

  if (latestBroadcastState == null) {
    final String streamUrl =
        baseUrl.replace(pathSegments: [...baseUrl.pathSegments, sessionId, 'stream.m3u8']).toString();

    return [
      WpPlayerStream(
        id: sessionId,
        phase: WpPhase.wpPhaseSession,
        url: NetworkUrlPrefixes.httpRequest.addPrefix(streamUrl),
        fromTime: Duration.zero,
        toTime: _longTimeFromNow,
        fadeOutTime: _streamFadeOutTime,
        loopContent: false,
        gain: 1.0,
        usesSidechain: false,
        sidechainGain: 0.0,
      ),
    ];
  }

  return latestBroadcastState.timeline.indexed.map((tuple) {
    final (int index, TimelineItem item) = tuple;
    final String streamUrl =
        baseUrl.replace(pathSegments: [...baseUrl.pathSegments, item.sessionId, 'stream.m3u8']).toString();
    late final Duration toTime;

    if (index == latestBroadcastState.timeline.length - 1) {
      toTime = _longTimeFromNow;
    } else {
      toTime = latestBroadcastState.timeline[index + 1].digitalSignalProcessingOffset + _streamFadeOutTime;
    }

    return WpPlayerStream(
      id: item.sessionId,
      phase: WpPhase.wpPhaseSession,
      url: NetworkUrlPrefixes.httpRequest.addPrefix(streamUrl),
      fromTime: item.digitalSignalProcessingOffset,
      toTime: toTime,
      fadeOutTime: _streamFadeOutTime,
      loopContent: false,
      gain: 1.0,
      usesSidechain: false,
      sidechainGain: 0.0,
    );
  }).toList();
}

List<WpPlayerStream> _getCustomVoiceoverStreams({
  required final ExternalOrchestratorEnvironment orchestratorEnvironment,
  required final List<VoiceoverStage>? voiceovers,
}) {
  if (voiceovers == null) return const [];

  final Uri voiceoverBaseUri = orchestratorEnvironment.customVoiceoverBaseUri;

  return voiceovers.map((voiceover) {
    final String streamUrl =
        voiceoverBaseUri
            .replace(pathSegments: [...voiceoverBaseUri.pathSegments, "${voiceover.fileNameWithoutExtension}.mp3"])
            .toString();
            
    return WpPlayerStream(
      id: 'vo-${voiceover.timing.from.inSeconds}-${voiceover.timing.to.inSeconds}-${voiceover.fileNameWithoutExtension}',
      phase: WpPhase.wpPhaseSession,
      url: NetworkUrlPrefixes.httpRequest.addPrefix(streamUrl),
      fromTime: voiceover.timing.from,
      toTime: voiceover.timing.to,
      fadeOutTime: Duration.zero,
      loopContent: false,
      gain: voiceover.volume ?? 1.0,
      usesSidechain: true,
      sidechainGain: 1.0 - (voiceover.musicGain ?? 1.0),
    );
  }).toList();
}

List<WpPlayerStream> _getFreeVoiceoverStreams({
  required final ExternalOrchestratorEnvironment orchestratorEnvironment,
  required final Duration sessionDuration,
  required final bool hasFreeVoiceover,
}) {
  if (!hasFreeVoiceover) return const [];

  final Uri freeVoiceoverUri = orchestratorEnvironment.freeVoiceoverBaseUri;
  final String freeVoiceoverPrefixedUrl = NetworkUrlPrefixes.httpRequest.addPrefix(freeVoiceoverUri.toString());

  final List<WpPlayerStream> result = [];

  for (Duration time = _freeVoiceoverStartOffset; time < sessionDuration; time += _freeVoiceoverEvery) {
    result.add(
      WpPlayerStream(
        id: 'freeVo-${time.inMilliseconds}',
        phase: WpPhase.wpPhaseSession,
        url: freeVoiceoverPrefixedUrl,
        fromTime: time,
        toTime: time + _freeVoiceoverDuration,
        fadeOutTime: Duration.zero,
        loopContent: false,
        gain: 1.0,
        usesSidechain: true,
        sidechainGain: 0.8,
      ),
    );
  }

  return result;
}
