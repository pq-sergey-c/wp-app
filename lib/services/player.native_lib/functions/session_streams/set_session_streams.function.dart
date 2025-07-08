import 'dart:ffi' as ffi;

import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';
import 'package:wp_player/services/player.native_lib/utils/ffi/make_wp_player_stream.list.native_lib.dart';

typedef _SetSessionStreamsNative =
    ffi.Int Function(NativeWpPlayerLibState state, ffi.Pointer<WpPlayerStreamNative> streams, ffi.Int streamCount);

typedef _SetSessionStreams =
    int Function(NativeWpPlayerLibState state, ffi.Pointer<WpPlayerStreamNative> streams, int streamCount);

_SetSessionStreams? _setSessionStreamsRef;

_SetSessionStreams _loadSetSessionStreams(ffi.DynamicLibrary libSource) {
  if (_setSessionStreamsRef != null) {
    return _setSessionStreamsRef!;
  }
  _setSessionStreamsRef = libSource.lookupFunction<_SetSessionStreamsNative, _SetSessionStreams>(
    'wp_playerlib_set_session',
  );
  return _setSessionStreamsRef!;
}

/// Returns [bool] - isSuccessful
bool setSessionStreamsNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
  final List<WpPlayerStream> streams,
) {
  final nativeListSize = constructWpPlayerStreamNativeList(streams); // should be deallocated
  late final int result;

  try {
    result = _loadSetSessionStreams(libSource)(state, nativeListSize.list, nativeListSize.size);
  } catch (_) {
    throw FlutterError("Failed to set session");
  }

  deallocWpPlayerStreamNativeList(nativeListSize.list, nativeListSize.size);
  return result == 0;
}
