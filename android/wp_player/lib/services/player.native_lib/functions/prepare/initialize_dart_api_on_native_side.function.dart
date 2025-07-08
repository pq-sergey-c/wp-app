import 'dart:ffi' as ffi;
import 'package:flutter/widgets.dart';

typedef _DartInitializeApiNative = ffi.IntPtr Function(ffi.Pointer<ffi.Void>);

typedef _DartInitializeApi = int Function(ffi.Pointer<ffi.Void>);

_DartInitializeApi? _initializeDartApi;

_DartInitializeApi _loadDartInitializeApi(ffi.DynamicLibrary libSource) {
  if (_initializeDartApi != null) {
    return _initializeDartApi!;
  }
  _initializeDartApi = libSource
      .lookupFunction<_DartInitializeApiNative, _DartInitializeApi>(
        'Dart_InitializeApi',
      );
  return _initializeDartApi!;
}

void initializeDartApiOnNativeSideNative(final ffi.DynamicLibrary libSource) {
  try {
    _loadDartInitializeApi(libSource)(ffi.NativeApi.initializeApiDLData);
  } catch (_) {
    throw FlutterError("Failed to initalize DartAPI on native side");
  }
}
