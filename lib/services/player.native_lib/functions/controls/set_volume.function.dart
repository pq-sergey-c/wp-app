import 'dart:ffi' as ffi;
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';

typedef _SetVolumeNative =
    ffi.Void Function(NativeWpPlayerLibState state, ffi.Float volume);

typedef _SetVolume = void Function(NativeWpPlayerLibState state, double volume);

_SetVolume? _setVolumeRef;

_SetVolume _loadSetVolume(ffi.DynamicLibrary libSource) {
  if (_setVolumeRef != null) {
    return _setVolumeRef!;
  }
  _setVolumeRef = libSource.lookupFunction<_SetVolumeNative, _SetVolume>(
    'wp_playerlib_set_volume',
  );
  return _setVolumeRef!;
}

void setVolumeNative(
  final ffi.DynamicLibrary libSource,
  final NativeWpPlayerLibState state,
  double volume,
) {
  const double floatPointErrorMargin = 0.001;
  const double volumeMin = 0.0;
  const double volumeMax = 1.0;

  if (volume < volumeMin - floatPointErrorMargin ||
      volume > volumeMax + floatPointErrorMargin) {
    throw FlutterError(
      "Volume value $volume is out of allowed range [$volumeMin; $volumeMax]",
    );
  }

  volume = max(min(volume, volumeMax), volumeMin);

  try {
    _loadSetVolume(libSource)(state, volume);
  } catch (_) {
    throw FlutterError("Failed to set volume value");
  }
}
