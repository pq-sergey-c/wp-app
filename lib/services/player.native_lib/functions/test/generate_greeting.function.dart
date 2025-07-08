import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as ffi_utils;

typedef _GenerateGreetingNative = ffi.Pointer<ffi_utils.Utf8> Function();

typedef _GenerateGreeting = ffi.Pointer<ffi_utils.Utf8> Function();

_GenerateGreeting? _generateGreetingRef;

_GenerateGreeting _loadGenerateGreeting(ffi.DynamicLibrary libSource) {
  if (_generateGreetingRef != null) {
    return _generateGreetingRef!;
  }
  _generateGreetingRef = libSource.lookupFunction<_GenerateGreetingNative, _GenerateGreeting>('hello_ohayo');
  return _generateGreetingRef!;
}

String generateGreetingNative(
  final ffi.DynamicLibrary libSource,
  final int number,
  final double divider,
  final String name,
) {
  final nameCString = name.toNativeUtf8(allocator: ffi_utils.calloc);
  late String result;
  try {
    final resultCString = _loadGenerateGreeting(libSource)();
    result = resultCString.toDartString();
    ffi_utils.calloc.free(resultCString);
  } catch (_) {
    result = 'Error';
  }

  ffi_utils.calloc.free(nameCString);
  return result;
}
