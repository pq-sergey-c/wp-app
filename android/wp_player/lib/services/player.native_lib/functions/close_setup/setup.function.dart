import 'dart:ffi' as ffi;

import 'package:flutter/widgets.dart';

typedef _SetupPlayerNative =
    ffi.Pointer<ffi.Void> Function(
      ffi.Double sampleRate,
      ffi.Int64 bufferingLookahead,
    );

typedef _SetupPlayer =
    ffi.Pointer<ffi.Void> Function(double sampleRate, int bufferingLookahead);

_SetupPlayer? _setupPlayerRef;

_SetupPlayer _loadSetupPlayer(ffi.DynamicLibrary libSource) {
  if (_setupPlayerRef != null) {
    return _setupPlayerRef!;
  }
  _setupPlayerRef = libSource.lookupFunction<_SetupPlayerNative, _SetupPlayer>(
    'wp_playerlib_create_wrapper',
  );
  return _setupPlayerRef!;
}

ffi.Pointer<ffi.Void> setupPlayerNative(
  final ffi.DynamicLibrary libSource,
  final double sampleRate,
  final int bufferingLookahead,
) {
  try {
    return _loadSetupPlayer(libSource)(sampleRate, bufferingLookahead);
  } catch (error) {
    throw FlutterError("Failed to setup native player");
  }
}
