import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi_utils;
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';
import 'package:wp_player/services/player.native_lib/utils/ffi/dart_bool_to_c_uint8_t.native_lib.dart';

ffi.Pointer<WpPlayerStreamNative> constructWpPlayerStreamNative(WpPlayerStream object) {
  final result = ffi_utils.calloc<WpPlayerStreamNative>(1);
  fillWpPlayerStreamNativePtr(result, object);
  return result;
}

void fillWpPlayerStreamNativePtr(ffi.Pointer<WpPlayerStreamNative> ptr, WpPlayerStream object) {
  ptr.ref.id = object.id.toNativeUtf8(allocator: ffi_utils.calloc);
  ptr.ref.phase = object.phase.value;
  ptr.ref.url = object.url.toNativeUtf8(allocator: ffi_utils.calloc);

  ptr.ref.fromTime = object.fromTime.inMilliseconds;
  ptr.ref.toTime = object.toTime.inMilliseconds;
  ptr.ref.fadeOutTime = object.fadeOutTime.inMilliseconds;

  ptr.ref.loopContent = boolToUint8T(object.loopContent);
  ptr.ref.gain = object.gain;
  ptr.ref.usesSidechain = boolToUint8T(object.usesSidechain);
  ptr.ref.sidechainGain = object.sidechainGain;
}

void deallocWpPlayerStreamNativePtr(ffi.Pointer<WpPlayerStreamNative> ptr) {
  ffi_utils.calloc.free(ptr.ref.id);
  ffi_utils.calloc.free(ptr.ref.url);
  ffi_utils.calloc.free(ptr);
}
