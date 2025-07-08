import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _SeekToTimeInPhaseNative =
    ffi.Int Function(NativeWpPlayerLibState state, ffi.Int64 timeWithinPhase);

typedef _SeekToTimeInPhase =
    int Function(NativeWpPlayerLibState state, int timeWithinPhase);

_SeekToTimeInPhase? _seekToTimeInPhaseRef;

_SeekToTimeInPhase _loadSeekToTimeInPhase(ffi.DynamicLibrary libSource) {
  if (_seekToTimeInPhaseRef != null) {
    return _seekToTimeInPhaseRef!;
  }
  _seekToTimeInPhaseRef = libSource
      .lookupFunction<_SeekToTimeInPhaseNative, _SeekToTimeInPhase>(
        'wp_playerlib_seek_to_time_in_phase',
      );
  return _seekToTimeInPhaseRef!;
}

void seekToTimeInPhaseNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
  final Duration seekTo,
) {
  late final bool isFailed;
  try {
    final int result = _loadSeekToTimeInPhase(libSource)(
      state,
      seekTo.inMilliseconds,
    );
    isFailed = result != 0;
  } catch (_) {
    isFailed = true;
  }
  if (isFailed) {
    throw FlutterError("Failed to seek to time in phase");
  }
}
