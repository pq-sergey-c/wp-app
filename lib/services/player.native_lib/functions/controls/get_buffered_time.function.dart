import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _GetBufferedTimeNative =
    ffi.Float Function(NativeWpPlayerLibState state);

typedef _GetBufferedTime = double Function(NativeWpPlayerLibState state);

_GetBufferedTime? _getBufferedTimeRef;

_GetBufferedTime _loadGetBufferedTime(ffi.DynamicLibrary libSource) {
  if (_getBufferedTimeRef != null) {
    return _getBufferedTimeRef!;
  }
  _getBufferedTimeRef = libSource
      .lookupFunction<_GetBufferedTimeNative, _GetBufferedTime>(
        'wp_playerlib_get_buffered_time',
      );
  return _getBufferedTimeRef!;
}

Duration getBufferedTimeNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    final double resultInSeconds = _loadGetBufferedTime(libSource)(state);
    return Duration(microseconds: (resultInSeconds * 1e6).round());
  } catch (_) {
    throw FlutterError("Failed to get buffered time");
  }
}
