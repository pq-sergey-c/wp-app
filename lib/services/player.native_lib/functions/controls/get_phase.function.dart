import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _GetPhaseNative = ffi.Int Function(NativeWpPlayerLibState state);

typedef _GetPhase = int Function(NativeWpPlayerLibState state);

_GetPhase? _getPhaseRef;

_GetPhase _loadGetPhase(ffi.DynamicLibrary libSource) {
  if (_getPhaseRef != null) {
    return _getPhaseRef!;
  }
  _getPhaseRef = libSource.lookupFunction<_GetPhaseNative, _GetPhase>(
    'wp_playerlib_get_phase',
  );
  return _getPhaseRef!;
}

WpPhase getPhaseNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    final int result = _loadGetPhase(libSource)(state);
    return WpPhase.fromInt(result);
  } catch (_) {
    throw FlutterError("Failed to get phase");
  }
}
