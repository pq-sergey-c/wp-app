import 'package:flutter/foundation.dart';
import 'package:wp_player/core/permissions/request_notification_permissions.dart';
import 'package:wp_player/services/external_orchestrator/external_orchestrator.service.interface.dart';
import 'package:wp_player/services/external_orchestrator/make_external_orchestrator.dart';
import 'package:wp_player/services/player.native_lib/player.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player/link_parser/parse_link.dart';
import 'package:wp_player/services/player/network/fetch_session.dart';
import 'package:wp_player/services/player/player.service.interface.dart';
import 'package:wp_player/services/player/prepare_streams/prepare_streams.dart';
import 'package:wp_player/services/player/types/link_session_info.player.dart';
import 'package:wp_player/services/player/types/session.player.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/types/session/session_render_type/session_render_type.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';
import 'package:wp_player/utils/logger/logger.dart';

const _fakeArtist = "Dr. Henry";

/// Singleton
class PlayerService implements IPlayerService {
  static final PlayerService _instance = PlayerService._internal();
  PlayerService._internal();

  factory PlayerService() {
    return _instance;
  }

  @override
  Future<void> disconnect() async {
    if (!NativeLibraryPlayer.isPlayerExist() || _session == null) return;

    final double oldVolume = volume;
    NativeLibraryPlayer().cleanUp();
    volume = oldVolume;

    _currentPlayTimeNotifier?.dispose();
    _currentPlayTimeNotifier = null;
    _playbackDurationNotifier?.dispose();
    _playbackDurationNotifier = null;
    _isConnectionInterruptedNotifier?.dispose();
    _isConnectionInterruptedNotifier = null;

    await _orchestrator?.dispose();
    _orchestrator = null;
    _session = null;
    _linkSessionInfo = null;

    _latestVoiceovers = null;
    _latestBroadcastState = null;
  }

  // -----------------------------------------------------------

  Session? _session;
  LinkSessionInfo? _linkSessionInfo;
  IExternalOrchestrator? _orchestrator;

  // Updated data from external orchestrator
  List<VoiceoverStage>? _latestVoiceovers;
  SessionBroadcastState? _latestBroadcastState;
  ValueNotifier<Duration?>? _currentPlayTimeNotifier;
  ValueNotifier<Duration?>? _playbackDurationNotifier;
  ValueNotifier<bool>? _isConnectionInterruptedNotifier; // websocket connection

  static const int bufferingLookaheadOffline = 10 * 60 * 60;
  static const int bufferingLookaheadOnline = 20 * 60;

  // -----------------------------------------------------------

  @override
  Future<bool> resolveLink(String link) async {
    await RequestNotificationPermissions.requestPermissionsToStartForegroundService();
    final LinkSessionInfo? linkSessionInfo = sessionServiceParseLink(link);
    if (linkSessionInfo == null) return false;

    try {
      final Session? session = await fetchSession(linkSessionInfo);
      if (session == null) return false;

      await _startSession(linkSessionInfo, session);
      return true;
    } catch (e) {
      logConsole.f("Player service failed to resolve link: $e");
      return false;
    }
  }

  // -----------------------------------------------------------

  @override
  Future<void> startSession() async => await _orchestrator?.startSessionEarly();

  @override
  void advanceFromPrelude() => _orchestrator?.broadcastUserAdvanceFromPrelude();

  @override
  void resume() {
    _assertPlayingStateNotifiersExist();
    _orchestrator?.resume();
  }

  @override
  void pause() {
    _assertPlayingStateNotifiersExist();
    _orchestrator?.pause();
  }

  @override
  double get volume => NativeLibraryPlayer().volume;

  @override
  set volume(double volume) => NativeLibraryPlayer().volume = volume;

  @override
  WpPhase get phase => NativeLibraryPlayer().phase;

  @override
  Duration get timeInPhase => NativeLibraryPlayer().timeInPhase;

  @override
  ValueListenable<bool>? get isPlayingListenable => NativeLibraryPlayer().isPlayingState;

  @override
  ValueListenable<Duration?>? get currentPlayTimeListenable => _currentPlayTimeNotifier;

  @override
  ValueListenable<Duration?>? get playbackDurationListenable => _playbackDurationNotifier;

  @override
  SessionInfo get sessionInformation {
    _assertSessionAndSessionInfoExist();

    return SessionInfo(
      id: _session!.id,
      title: _session!.sessionName,
      sessionType: _session!.renderType,
      artist: _fakeArtist,
      deviceInfo: "Desktop → iPhone 16",
      imageUrl: "",
      atmosphereColors: _session!.score.atmosphereColors,
      emotionalIntensity: _session!.score.emotionalIntensity,
      userRole: _userRole,
      providerControlUri: _session!.getProviderControlUri(_userRole, _linkSessionInfo!.externalOrchestratorEnv),
    );
  }

  @override
  bool get canControlPlayback {
    _assertSessionAndSessionInfoExist();
    return _isOffline || _session!.canClientStartEarly;
  }

  @override
  void reportConnectionIssue() => _isConnectionInterruptedNotifier?.value = true;

  @override
  void reportConnectionRestored() => _isConnectionInterruptedNotifier?.value = false;

  @override
  ValueListenable<bool>? get isConnectionInterruptedListenable => _isConnectionInterruptedNotifier;

  // -----------------------------------------------------------

  bool get _isOffline {
    _assertSessionAndSessionInfoExist();
    return _session!.renderType == SessionRenderType.preRendered || _session!.endTime != null;
  }

  Future<void> _startSession(LinkSessionInfo linkSessionInfo, Session session) async {
    await disconnect();

    _session = session;
    _linkSessionInfo = linkSessionInfo;

    _latestVoiceovers = session.score.voiceovers;

    _currentPlayTimeNotifier = ValueNotifier(null);
    _playbackDurationNotifier = ValueNotifier(null);
    _isConnectionInterruptedNotifier = ValueNotifier(false);

    final bool isOffline = _isOffline;
    NativeLibraryPlayer.rebuild(bufferingLookahead: isOffline ? bufferingLookaheadOffline : bufferingLookaheadOnline);

    _latestBroadcastState = _session!.broadcastState;
    _orchestrator = await _makeExternalOrchestrator(isOffline: isOffline);
    await _orchestrator!.start();

    _updateStreams();
  }

  Future<IExternalOrchestrator> _makeExternalOrchestrator({required bool isOffline}) async {
    _assertSessionAndSessionInfoExist();

    if (isOffline) {
      return await makeOfflineExternalOrchestrator(
        callbackSetBroadcastState: _callbackSetBroadcastState,
        callbackSetSessionDuration: _callbackSetSessionDuration,
        callbackSetPlaybackTime: _callbackSetPlaybackTime,
        sessionId: _session!.id,
        broadcastState: _session!.broadcastState,
        sessionDuration: _session!.duration,
        sessionScore: _session!.score,
        artist: _fakeArtist,
        sessionName: _session!.sessionName,
      );
    }

    return makeOnlineExternalOrchestrator(
      callbackSetBroadcastState: _callbackSetBroadcastState,
      callbackSetVoiceovers: _callbackSetVoiceovers,
      callbackSetSessionDuration: _callbackSetSessionDuration,
      callbackSetPlaybackTime: _callbackSetPlaybackTime,
      environment: _linkSessionInfo!.externalOrchestratorEnv,
      broadcastId: _linkSessionInfo!.broadcastId,
      sessionId: _session!.id,
      sessionScore: _session!.score,
      artist: _fakeArtist,
      sessionName: _session!.sessionName,
    );
  }

  void _callbackSetBroadcastState(SessionBroadcastState sessionBroadcastState) {
    _latestBroadcastState = sessionBroadcastState;
    _updateStreams();
  }

  void _callbackSetSessionDuration(Duration sessionDuration) {
    _assertPlayingStateNotifiersExist();
    final Duration? oldValue = _playbackDurationNotifier!.value;
    if (oldValue != null && oldValue == sessionDuration) return;

    _playbackDurationNotifier!.value = sessionDuration;
    _updateStreams();
  }

  void _callbackSetVoiceovers(List<VoiceoverStage> voiceovers) {
    _latestVoiceovers = voiceovers;
    _updateStreams();
  }

  void _callbackSetPlaybackTime(Duration currentPlayTime) {
    _assertPlayingStateNotifiersExist();
    _currentPlayTimeNotifier!.value = currentPlayTime;
  }

  void _updateStreams() {
    _assertSessionAndSessionInfoExist();
    _assertPlayingStateNotifiersExist();

    final streams = getStreams(
      latestBroadcastState: _latestBroadcastState,
      orchestratorEnvironment: _linkSessionInfo!.externalOrchestratorEnv,
      broadcastId: _linkSessionInfo!.broadcastId,
      sessionId: _session!.id,
      voiceovers: _latestVoiceovers,
      sessionDuration: _playbackDurationNotifier!.value ?? Duration.zero,
      hasFreeVoiceover: _linkSessionInfo!.withFreeVoiceover,
    );

    NativeLibraryPlayer().setStreams(streams);
  }

  // -----------------------------------------------------------

  void _assertSessionAndSessionInfoExist() {
    if (_session == null || _linkSessionInfo == null) {
      throw StateError("Player state invalid: session and sessionInfo must not be null");
    }
  }

  bool _isPlayingStateNotifiersExist() {
    return _currentPlayTimeNotifier != null &&
        _playbackDurationNotifier != null &&
        _isConnectionInterruptedNotifier != null;
  }

  void _assertPlayingStateNotifiersExist() {
    if (!_isPlayingStateNotifiersExist()) {
      throw StateError("Player state invalid: player state notifiers must not be null");
    }
  }

  // -----------------------------------------------------------
  // TODO: to remove after obtained from link/QR

  UserRole _userRole = UserRole.listener;

  @override
  set streamingType(UserRole userRole) => _userRole = userRole;
}
