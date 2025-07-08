import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi_utils;
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';

class WpPlayerStream {
  String id;
  WpPhase phase;
  String url;

  Duration fromTime;
  Duration toTime;
  Duration fadeOutTime;

  bool loopContent;

  /// in dB
  double gain;

  bool usesSidechain;

  /// in dB
  double sidechainGain;

  WpPlayerStream({
    required this.id,
    required this.phase,
    required this.url,
    required this.fromTime,
    required this.toTime,
    required this.fadeOutTime,
    required this.loopContent,
    required this.gain,
    required this.usesSidechain,
    required this.sidechainGain,
  });
}

final class WpPlayerStreamNative extends ffi.Struct {
  external ffi.Pointer<ffi_utils.Utf8> id;

  @ffi.Int()
  external int phase;

  external ffi.Pointer<ffi_utils.Utf8> url;

  @ffi.Int64()
  external int fromTime;
  @ffi.Int64()
  external int toTime;
  @ffi.Int64()
  external int fadeOutTime;

  @ffi.Uint8()
  external int loopContent;

  @ffi.Float()
  external double gain;
  @ffi.Uint8()
  external int usesSidechain;
  @ffi.Float()
  external double sidechainGain;
}
