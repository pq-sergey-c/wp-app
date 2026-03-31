import 'package:flutter/foundation.dart';
import 'package:wp_player/services/player.native_lib/types/callback_functions.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';

abstract class INativePlayer {
  /// Returns [bool] - isStarted
  bool start();

  /// Returns [bool] - isStopped
  bool stop();

  /// Returns [bool] - isEmittingSound (original name isStarted)
  ///   The player may be in a "stopped" state but still emit sound
  ///   (e.g. due to fade-out effect)
  /// Returns [null] - on error
  bool? isEmittingSound();

  /// Returns [ValueNotifier<bool>] - reflects whether the player is currently
  /// playing or in the process of starting
  ///
  /// In other words notifies listeners about state change due to call of [start] or [stop] methods
  ValueNotifier<bool> get isPlayingState;

  /// Network callbacks - are callbacks that are called when library
  /// needs another chunk of data (which needs to be provided from dart).
  /// Or it can be called when it cancels previous request
  ///
  /// [id] in callback is request's id, you need this number
  /// to respond with network result
  ///
  void setNetworkCallbacks(WpCallbackRequestData requestCallback, WpCallbackCancelFetch cancelRequestCallback);

  /// **Note**: throws
  Future<void> respondOnNetworkRequest(int id, List<int>? data, String fileExtension, {required bool isSuccessful});

  /// Start and run main loop of native player.
  ///
  /// Returns [bool] if isFinishedSuccessfully
  ///
  /// **Note**: throws
  bool setStreams(List<WpPlayerStream> streams);

  /// [double] - value in range [0.0, 1.0]
  double get volume;

  /// [volume] - value in range [0.0, 1.0]
  ///
  /// **Note**: throws
  set volume(double volume);

  /// Returns [ValueNotifier<WpPhase>] - reflects last set phase
  ///
  /// In other words notifies listeners about state change due to call of [changePhaseTo]
  ValueNotifier<WpPhase> get lastSetPhase;

  /// Shows real player state
  ///
  /// **Note**: throws
  WpPhase get realPhasePlayerIn;

  /// [at] - offset in phase
  ///
  /// **Note**: throws
  void changePhaseTo(WpPhase phase, {required Duration at});

  /// **Note**: throws
  Duration get timeInPhase;

  /// **Note**: throws
  void seekToTimeInPhase(Duration time);

  /// **Note**: throws
  Duration get bufferedTime;

  /// Whether at least one audio chunk has started playing since the last engine start
  bool get hasAudioStarted;

  /// Test function
  String generateGreeting(int number, double divider, String name);
}
