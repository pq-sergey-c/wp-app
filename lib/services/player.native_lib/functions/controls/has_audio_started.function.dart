import 'dart:ffi' as ffi;
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _HasAudioStartedNative = ffi.Bool Function(NativeWpPlayerLibState);

typedef _HasAudioStarted = bool Function(NativeWpPlayerLibState);

_HasAudioStarted? _hasAudioStartedRef;

_HasAudioStarted _loadHasAudioStarted(ffi.DynamicLibrary libSource) {
  if (_hasAudioStartedRef != null) {
    return _hasAudioStartedRef!;
  }
  _hasAudioStartedRef = libSource
      .lookupFunction<_HasAudioStartedNative, _HasAudioStarted>(
        'wp_playerlib_has_audio_started',
      );
  return _hasAudioStartedRef!;
}

bool hasAudioStartedNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    return _loadHasAudioStarted(libSource)(state);
  } catch (_) {
    return false;
  }
}
