import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _GetTimeInPhaseNative = ffi.Int Function(NativeWpPlayerLibState state);

typedef _GetTimeInPhase = int Function(NativeWpPlayerLibState state);

_GetTimeInPhase? _getTimeInPhaseRef;

_GetTimeInPhase _loadGetTimeInPhase(ffi.DynamicLibrary libSource) {
  if (_getTimeInPhaseRef != null) {
    return _getTimeInPhaseRef!;
  }
  _getTimeInPhaseRef = libSource
      .lookupFunction<_GetTimeInPhaseNative, _GetTimeInPhase>(
        'wp_playerlib_get_time_in_phase',
      );
  return _getTimeInPhaseRef!;
}

Duration getTimeInPhaseNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    final int result = _loadGetTimeInPhase(libSource)(state);
    return Duration(milliseconds: result);
  } catch (_) {
    throw FlutterError("Failed to get time in phase");
  }
}
