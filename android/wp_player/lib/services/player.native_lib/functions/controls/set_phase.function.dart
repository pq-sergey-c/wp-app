import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _SetPhaseNative =
    ffi.Int Function(
      NativeWpPlayerLibState state,
      ffi.Int phase,
      ffi.Int64 timeWithinPhase,
    );

typedef _SetPhase =
    int Function(NativeWpPlayerLibState state, int phase, int timeWithingPhase);

_SetPhase? _setPhaseRef;

_SetPhase _loadSetPhase(ffi.DynamicLibrary libSource) {
  if (_setPhaseRef != null) {
    return _setPhaseRef!;
  }
  _setPhaseRef = libSource.lookupFunction<_SetPhaseNative, _SetPhase>(
    'wp_playerlib_set_phase',
  );
  return _setPhaseRef!;
}

void setPhaseNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
  final WpPhase phase,
  final Duration timeWithinPhase,
) {
  late final bool isFailed;
  try {
    final int result = _loadSetPhase(libSource)(
      state,
      phase.value,
      timeWithinPhase.inMilliseconds,
    );
    isFailed = result != 0;
  } catch (_) {
    isFailed = true;
  }
  if (isFailed) {
    throw FlutterError("Failed to set phase");
  }
}
