import 'dart:ffi' as ffi;
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _StartPlayerNative = ffi.Int Function(NativeWpPlayerLibState);

typedef _StartPlayer = int Function(NativeWpPlayerLibState);

_StartPlayer? _startPlayerRef;

_StartPlayer _loadStartPlayer(ffi.DynamicLibrary libSource) {
  if (_startPlayerRef != null) {
    return _startPlayerRef!;
  }
  _startPlayerRef = libSource.lookupFunction<_StartPlayerNative, _StartPlayer>(
    'wp_playerlib_start',
  );
  return _startPlayerRef!;
}

bool startPlayerNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    return _loadStartPlayer(libSource)(state) == 0;
  } catch (_) {
    return false;
  }
}
