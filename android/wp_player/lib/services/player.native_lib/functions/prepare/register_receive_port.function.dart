import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'package:flutter/widgets.dart';

typedef _RegisterReceivePortNative = ffi.IntPtr Function(ffi.Int64);

typedef _RegisterReceivePort = int Function(int);

_RegisterReceivePort? _registerReceivePort;

_RegisterReceivePort _loadRegisterReceivePort(ffi.DynamicLibrary libSource) {
  if (_registerReceivePort != null) {
    return _registerReceivePort!;
  }
  _registerReceivePort = libSource.lookupFunction<_RegisterReceivePortNative, _RegisterReceivePort>(
    'wp_playerlib_register_native_port',
  );
  return _registerReceivePort!;
}

void registerReceivePortNative(final ffi.DynamicLibrary libSource, final ReceivePort receivePort) {
  try {
    _loadRegisterReceivePort(libSource)(receivePort.sendPort.nativePort);
  } catch (_) {
    throw FlutterError("Error while registering/listening");
  }
}
