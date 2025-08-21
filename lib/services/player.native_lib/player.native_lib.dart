import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wp_player/services/player.native_lib/functions/close_setup/close.function.dart';
import 'package:wp_player/services/player.native_lib/functions/close_setup/setup.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/get_buffered_time.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/get_phase.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/get_time_in_phase.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/seek_to_time_in_phase.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/set_phase.function.dart';
import 'package:wp_player/services/player.native_lib/functions/controls/set_volume.function.dart';
import 'package:wp_player/services/player.native_lib/functions/network/return_data_on_response.function.dart';
import 'package:wp_player/services/player.native_lib/functions/prepare/initialize_dart_api_on_native_side.function.dart';
import 'package:wp_player/services/player.native_lib/functions/prepare/register_receive_port.function.dart';
import 'package:wp_player/services/player.native_lib/functions/session_streams/set_session_streams.function.dart';
import 'package:wp_player/services/player.native_lib/functions/test/generate_greeting.function.dart';
import 'package:wp_player/services/player.native_lib/functions/work_cycle/is_started.function.dart';
import 'package:wp_player/services/player.native_lib/functions/work_cycle/start.function.dart';
import 'package:wp_player/services/player.native_lib/functions/work_cycle/stop.function.dart';
import 'package:wp_player/services/player.native_lib/player_interface.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/callback_functions.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/native_message.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';
import 'package:wp_player/services/player.native_lib/utils/ffi/resolve_native_message.native_lib.dart';
import 'package:wp_player/services/player.native_lib/utils/platform/get_native_library_relative_path.native_lib.dart';

/// Re-makeable singleton (soft singleton)
class NativeLibraryPlayer implements INativePlayer {
  static const double _defaultSampleRate = 48000.0;
  static const int _defaultBufferingLookahead = 100000;
  static final String _nativeLibraryName = getNativeLibraryRelativePath();

  // Library state
  NativeWpPlayerLibState _playerHandler = ffi.nullptr;
  static final ValueNotifier<bool> _isPlayingState = ValueNotifier(false);
  static final ValueNotifier<WpPhase> _playingPhase = ValueNotifier(WpPhase.wpPhaseNone);

  // Global - data
  ffi.DynamicLibrary _nativeLibrary;
  static NativeLibraryPlayer? _instance;
  static bool isInitiallySetup = false;

  // Global - native port
  static final _callbackReady = Completer<void>();
  static WpCallbackRequestData? _requestCallback;
  static WpCallbackCancelFetch? _cancelRequestCallback;

  /// native wrapper assumes existence of only one port at the point of time
  static final ReceivePort _receivePort = ReceivePort();

  // Local
  double _volume = 0.0;

  // =====================[]---------------------
  //                    Behavior
  // ---------------------[]=====================
  NativeLibraryPlayer._internal(double sampleRate, int bufferingLookahead)
    : _nativeLibrary = ffi.DynamicLibrary.open(_nativeLibraryName) {
    _playerHandler = setupPlayerNative(_nativeLibrary, sampleRate, bufferingLookahead);

    if (!isInitiallySetup) {
      initializeDartApiOnNativeSideNative(_nativeLibrary);
      _receivePort.listen(_nativePortListener);
      registerReceivePortNative(_nativeLibrary, _receivePort);
      isInitiallySetup = true;
    }
  }

  factory NativeLibraryPlayer({double? sampleRate, int? bufferingLookahead}) {
    _instance ??= NativeLibraryPlayer._internal(
      sampleRate ?? _defaultSampleRate,
      bufferingLookahead ?? _defaultBufferingLookahead,
    );
    return _instance!;
  }

  factory NativeLibraryPlayer.rebuild({double? sampleRate, int? bufferingLookahead}) {
    final oldVolume = _instance?.volume ?? 0;

    if (_instance != null) {
      _instance!.cleanUp();
    }

    final newPlayer = NativeLibraryPlayer(sampleRate: sampleRate, bufferingLookahead: bufferingLookahead)
      ..volume = oldVolume;

    return newPlayer; // newPlayer is the same as _instance in this moment
  }

  void cleanUp() {
    closePlayerNative(_nativeLibrary, _playerHandler);
    _instance = null;
    _isPlayingState.value = false;
    _playingPhase.value = WpPhase.wpPhaseNone;
  }

  static bool isPlayerExist() {
    return _instance != null;
  }

  // =====================[]---------------------
  //                  Native port
  // ---------------------[]=====================
  static Future<void> _nativePortListener(dynamic message) async {
    if (!_callbackReady.isCompleted) {
      // wait for callback to be provided
      await _callbackReady.future;
    }
    final (:data, :type) = resolveNativeMessage(message);
    switch (type) {
      case WpNativeMessageType.dataRequest:
        unawaited(_requestCallback!(data as WpDataRequest));
        return;
      case WpNativeMessageType.cancelFetchRequest:
        unawaited(_cancelRequestCallback!(data as WpDataCancelRequest));
        return;
    }
  }

  // =====================[]---------------------
  //                   Functions
  // ---------------------[]=====================

  @override
  bool start() {
    _isPlayingState.value = true;
    return startPlayerNative(_nativeLibrary, _playerHandler);
  }

  @override
  bool stop() {
    _isPlayingState.value = false;
    return stopPlayerNative(_nativeLibrary, _playerHandler);
  }

  @override
  bool? isEmittingSound() => isStartedPlayerNative(_nativeLibrary, _playerHandler);

  @override
  ValueNotifier<bool> get isPlayingState => _isPlayingState;

  @override
  void setNetworkCallbacks(WpCallbackRequestData requestCallback, WpCallbackCancelFetch cancelRequestCallback) {
    _requestCallback = requestCallback;
    _cancelRequestCallback = cancelRequestCallback;
    if (!_callbackReady.isCompleted) {
      // unblock native port listener
      _callbackReady.complete();
    }
  }

  @override
  Future<void> respondOnNetworkRequest(
    int id,
    List<int>? data,
    String fileExtension, {
    required bool isSuccessful,
  }) async {
    await respondOnNetworkRespondNative(
      _nativeLibraryName,
      _playerHandler,
      id,
      data,
      fileExtension,
      isSuccessful: isSuccessful,
    );
  }

  @override
  bool setStreams(List<WpPlayerStream> streams) {
    return setSessionStreamsNative(_nativeLibrary, _playerHandler, streams);
  }

  @override
  double get volume => _volume;

  @override
  set volume(double volume) {
    const floatErrorMargin = 0.00001;
    assert(
      volume >= 0.0 - floatErrorMargin && volume <= 1.0 + floatErrorMargin,
      'volume should be in range [0.0, 1.0]',
    );
    _volume = min(max(0, volume), 1);
    setVolumeNative(_nativeLibrary, _playerHandler, _volume);
  }

  @override
  WpPhase get realPhasePlayerIn => getPhaseNative(_nativeLibrary, _playerHandler);

  @override
  ValueNotifier<WpPhase> get lastSetPhase => _playingPhase;

  @override
  void changePhaseTo(WpPhase phase, {required Duration at}) {
    assert(!at.isNegative, 'at must be >= 0');
    setPhaseNative(_nativeLibrary, _playerHandler, phase, at);
    _playingPhase.value = phase;
  }

  @override
  Duration get timeInPhase => getTimeInPhaseNative(_nativeLibrary, _playerHandler);

  @override
  void seekToTimeInPhase(Duration time) {
    assert(!time.isNegative, 'time must be >= 0');
    seekToTimeInPhaseNative(_nativeLibrary, _playerHandler, time);
  }

  @override
  Duration get bufferedTime => getBufferedTimeNative(_nativeLibrary, _playerHandler);

  @override
  String generateGreeting(final int number, final double divider, final String name) {
    return generateGreetingNative(_nativeLibrary, number, divider, name);
  }
}
