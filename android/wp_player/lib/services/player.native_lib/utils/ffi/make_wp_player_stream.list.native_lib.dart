import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi_utils;
import 'package:wp_player/services/player.native_lib/types/stream.native_lib.dart';
import 'package:wp_player/services/player.native_lib/utils/ffi/make_wp_player_stream.native_lib.dart';

({ffi.Pointer<WpPlayerStreamNative> list, int size}) constructWpPlayerStreamNativeList(
  List<WpPlayerStream> listSource,
) {
  final result = ffi_utils.calloc<WpPlayerStreamNative>(listSource.length);
  for (int element = 0; element < listSource.length; ++element) {
    final ptr = result + element; // pointer arithmetic
    fillWpPlayerStreamNativePtr(ptr, listSource[element]);
  }
  return (list: result, size: listSource.length);
}

void deallocWpPlayerStreamNativeList(ffi.Pointer<WpPlayerStreamNative> list, int size) {
  for (int element = 0; element < size; ++element) {
    final ptr = list + element; // pointer arithmetic
    ffi_utils.calloc.free(ptr.ref.id);
    ffi_utils.calloc.free(ptr.ref.url);
  }
  ffi_utils.calloc.free(list);
}
