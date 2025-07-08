import 'dart:ffi' as ffi;
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _IsStartedPlayerNative = ffi.Bool Function(NativeWpPlayerLibState);

typedef _IsStartedPlayer = bool Function(NativeWpPlayerLibState);

_IsStartedPlayer? _isStartedPlayerRef;

_IsStartedPlayer _loadIsStartedPlayer(ffi.DynamicLibrary libSource) {
  if (_isStartedPlayerRef != null) {
    return _isStartedPlayerRef!;
  }
  _isStartedPlayerRef = libSource
      .lookupFunction<_IsStartedPlayerNative, _IsStartedPlayer>(
        'wp_playerlib_is_started',
      );
  return _isStartedPlayerRef!;
}

bool? isStartedPlayerNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    return _loadIsStartedPlayer(libSource)(state);
  } catch (_) {
    return null;
  }
}
