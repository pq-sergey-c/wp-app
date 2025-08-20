// Note: current implementation ignores expectsAtParameter

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:wp_player/services/network/network.service.interface.dart';
import 'package:wp_player/services/network/types/enums/network_url_prefixes.dart';
import 'package:wp_player/services/player.native_lib/player.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/native_message.native_lib.dart';
import 'package:wp_player/utils/logger/logger.dart';

typedef _ResponseTuple = ({bool ignore, Uint8List? data, String? fileExtension, bool success});

/// Singleton
class NetworkService implements INetworkService {
  static final NetworkService _instance = NetworkService._internal();

  factory NetworkService() {
    return _instance;
  }

  NetworkService._internal();

  // ------------------------------------------------

  final Map<int, CancelableOperation<_ResponseTuple>> _cancelableOperations = {};

  @override
  Future<void> onNetworkRequest(WpDataRequest data) async {
    final cancelable = CancelableOperation<_ResponseTuple>.fromFuture(
      _networkCall(data),
      onCancel: () => _cancelableOperations.remove(data.id),
    );
    _cancelableOperations[data.id] = cancelable;

    final result = await cancelable.valueOrCancellation(null);
    if (result == null) return;
    await _handleResponse(data.id, result);
  }

  @override
  Future<void> onNetworkCancel(WpDataCancelRequest data) async {
    final CancelableOperation? completer = _cancelableOperations.remove(data.id);
    if (completer != null && !completer.isCompleted) await completer.cancel();
  }

  // ------------------------------------------------

  Future<_ResponseTuple> _networkCall(WpDataRequest data) async {
    late final Uint8List blob;
    final (:String? clearedString, :NetworkUrlPrefixes? type) = NetworkUrlPrefixes.resolveString(data.url);

    if (type == null || clearedString == null) {
      logConsole.f('Network service: invalid or missing URL prefix in "${data.url}"');
      return (ignore: true, data: null, success: false, fileExtension: null);
    }
    final String? fileExtension = clearedString.contains('.') ? clearedString.split('.').last : null;

    switch (type) {
      case NetworkUrlPrefixes.localFile:
        // TODO: add file check or something
        blob = (await rootBundle.load(clearedString)).buffer.asUint8List();
        return (ignore: false, data: blob, success: true, fileExtension: fileExtension);
      case NetworkUrlPrefixes.httpRequest:
        final http.Response response = await http.get(Uri.parse(clearedString), headers: {"Accept": "*/*"});
        return (
          ignore: false,
          data: response.bodyBytes,
          success: response.statusCode == 200,
          fileExtension: fileExtension,
        );
    }
  }

  Future<void> _handleResponse(int id, _ResponseTuple resultTuple) async {
    if (resultTuple.ignore) return;
    await NativeLibraryPlayer().respondOnNetworkRequest(
      id,
      resultTuple.data,
      resultTuple.fileExtension ?? '',
      isSuccessful: resultTuple.success,
    );
  }

  // ------------------------------------------------
  // CONTINUE: 4 add 3-rd here
  // CONTINUE: 5 (and then it can be used as NetworkService().whateverYouWouldNameIt(PlayerService().sessionInfo))
}
