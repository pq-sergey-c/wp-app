import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _ClosePlayerNative = ffi.Void Function(NativeWpPlayerLibState);

typedef _ClosePlayer = void Function(NativeWpPlayerLibState);

_ClosePlayer? _closePlayerRef;

_ClosePlayer _loadClosePlayer(ffi.DynamicLibrary libSource) {
  if (_closePlayerRef != null) {
    return _closePlayerRef!;
  }
  _closePlayerRef = libSource.lookupFunction<_ClosePlayerNative, _ClosePlayer>(
    'wp_playerlib_destroy',
  );
  return _closePlayerRef!;
}

void closePlayerNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
) {
  try {
    _loadClosePlayer(libSource)(state);
  } catch (_) {
    throw FlutterError("Failed to close native player");
  }
}
