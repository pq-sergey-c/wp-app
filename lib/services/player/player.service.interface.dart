import 'package:flutter/foundation.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

/// Coupled with player.native_lib service
/// and via it, also, indirectly, with network.service service
abstract class IPlayerService {
  /// [Future<bool>] - is correct link
  Future<bool> resolveLink(String link);

  Future<void> disconnect();

  Future<void> startSession();

  void advanceFromPrelude();

  void resume();

  void pause();

  /// [double] - value in range [0.0, 1.0]
  double get volume;

  /// [volume] - value in range [0.0, 1.0]
  set volume(double volume);

  ValueListenable<WpPhase> get phase;

  Duration get timeInPhase;

  ValueListenable<bool>? get isPlayingListenable;

  ValueListenable<Duration?>? get currentPlayTimeListenable;

  ValueListenable<Duration?>? get playbackDurationListenable;

  ValueListenable<Duration?>? get bufferedTimeListenable;

  SessionInfo get sessionInformation;

  bool get canControlPlayback;

  /// Report that a websocket connection issue has been detected
  void reportConnectionIssue();

  /// Report that websocket connection has been restored
  void reportConnectionRestored();

  bool get isOffline;

  ValueListenable<bool>? get isConnectionInterruptedListenable;

  set streamingType(UserRole userRole); // TODO: remove once this info is obtained from link / QR
}
