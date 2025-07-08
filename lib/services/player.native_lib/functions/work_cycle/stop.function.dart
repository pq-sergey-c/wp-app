import 'dart:ffi' as ffi;
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _StopPlayerNative = ffi.Int Function(NativeWpPlayerLibState);

typedef _StopPlayer = int Function(NativeWpPlayerLibState);

_StopPlayer? _stopPlayerRef;

_StopPlayer _loadStopPlayer(ffi.DynamicLibrary libSource) {
  if (_stopPlayerRef != null) {
    return _stopPlayerRef!;
  }
  _stopPlayerRef = libSource.lookupFunction<_StopPlayerNative, _StopPlayer>(
    'wp_playerlib_stop',
  );
  return _stopPlayerRef!;
}

bool stopPlayerNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    return _loadStopPlayer(libSource)(state) == 0;
  } catch (_) {
    return false;
  }
}
