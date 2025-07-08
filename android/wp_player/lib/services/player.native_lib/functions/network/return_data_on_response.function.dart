import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi_utils;
import 'package:flutter/widgets.dart';
import 'package:wp_player/services/player.native_lib/types/types.native_lib.dart';
import 'package:wp_player/services/temp_storage/temp_storage.service.dart';

typedef _RespondOnNetworkRespondNative =
    ffi.Void Function(
      NativeWpPlayerLibState state,
      ffi.Uint32 id,
      ffi.Int32 status,
      ffi.Pointer<ffi_utils.Utf8> filePath,
    );

typedef _RespondOnNetworkRespond =
    void Function(NativeWpPlayerLibState state, int id, int status, ffi.Pointer<ffi_utils.Utf8> filePath);

_RespondOnNetworkRespond? _respondOnNetworkRespondRef;

_RespondOnNetworkRespond _loadRegisterCallbacks(ffi.DynamicLibrary libSource) {
  if (_respondOnNetworkRespondRef != null) {
    return _respondOnNetworkRespondRef!;
  }
  _respondOnNetworkRespondRef = libSource.lookupFunction<_RespondOnNetworkRespondNative, _RespondOnNetworkRespond>(
    'wp_playerlib_on_network_response',
  );
  return _respondOnNetworkRespondRef!;
}

// --------------------------------------------------------------------------
// Isolate // TODO: assess possibility of making long running isolate for this function to remove build-dispose overhead

class _IsolateArgs {
  const _IsolateArgs({
    required this.libPath,
    required this.pointerAddressToState,
    required this.id,
    required this.data,
    required this.fileExtension,
    required this.isSuccessful,
    required this.serializedTempStorageService,
    required this.sendPort,
  });

  final String libPath;
  final int pointerAddressToState;
  final int id;
  final List<int>? data;
  final String fileExtension;
  final bool isSuccessful;
  final String serializedTempStorageService;

  final SendPort sendPort;
}

Future<void> _isolateRespondOnNetworkRespondNative(_IsolateArgs args) async {
  final lib = ffi.DynamicLibrary.open(args.libPath);
  final state = ffi.Pointer<NativeWpPlayerLibStatePointerType>.fromAddress(args.pointerAddressToState);

  String? filePath;

  if (args.data != null) {
    final extension = args.fileExtension.isEmpty ? "" : '.${args.fileExtension}';
    filePath = await TempStorageService.deserializeForIsolate(
      args.serializedTempStorageService,
    ).writeFileToTempDir(args.data!, fileName: 'native_audio_${args.id}.wavepath_temp$extension');
  }

  final ffi.Pointer<ffi_utils.Utf8> filePathAllocated =
      filePath == null ? ffi.nullptr : filePath.toNativeUtf8(allocator: ffi_utils.calloc);

  try {
    _loadRegisterCallbacks(lib)(
      state,
      args.id,
      args.isSuccessful ? 0 : 1, // POSIX/Unix style
      filePathAllocated,
    );
  } catch (_) {
    throw FlutterError("Failed to respond with network data to player");
  } finally {
    if (filePathAllocated != ffi.nullptr) ffi_utils.calloc.free(filePathAllocated);
    args.sendPort.send(null);
  }
}

// --------------------------------------------------------------------------

Future<void> respondOnNetworkRespondNative(
  final String libSourcePath,
  final NativeWpPlayerLibState state,
  final int id,
  List<int>? data,
  String fileExtension, {
  required bool isSuccessful,
}) async {
  final tempStorage = await TempStorageService.instanceForMainIsolate;

  final receivePort = ReceivePort();

  final args = _IsolateArgs(
    libPath: libSourcePath,
    pointerAddressToState: state.address,
    id: id,
    data: data,
    fileExtension: fileExtension,
    isSuccessful: isSuccessful,
    serializedTempStorageService: tempStorage.serializeForIsolate(),
    sendPort: receivePort.sendPort,
  );

  await Isolate.spawn(_isolateRespondOnNetworkRespondNative, args);
  await receivePort.first;
}
