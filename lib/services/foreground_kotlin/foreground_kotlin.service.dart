import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:wp_player/services/foreground_kotlin/foreground_kotlin.service.interface.dart';

const String _mainDartToKotlinForegroundChannel = 'wp_foreground_bridge_main_isolate';
const String _mainDartToKotlinControlChannel = 'wp_foreground_bridge_control';
const String _noResponse = "";

const String _controlMessageStart = "startForeground";
const String _controlMessageDoesExist = "doesForegroundExist";
const String _controlMessageDispose = "disposeForeground";

class ForegroundKotlinService implements IForegroundKotlinService {
  static final ForegroundKotlinService _instance = ForegroundKotlinService._internal();
  ForegroundKotlinService._internal();

  factory ForegroundKotlinService() => _instance;

  void Function(String)? _messageHandlerCallback;

  /// to ensure correctness of start/dispose cycle
  final Mutex _uptimeMutex = Mutex();

  final BasicMessageChannel<String> _channelToForeground = const BasicMessageChannel<String>(
    _mainDartToKotlinForegroundChannel,
    StringCodec(),
  );

  final BasicMessageChannel<String> _controlChannelToKotlin = const BasicMessageChannel<String>(
    _mainDartToKotlinControlChannel,
    StringCodec(),
  );

  // --------------------------------------------------------------

  @override
  Future<void> start() async {
    await ensureStopped();
    _channelToForeground.setMessageHandler(_messageHandler);

    await _uptimeMutex.protect(() async {
      await _controlChannelToKotlin.send(_controlMessageStart);
    });
  }

  @override
  Future<void> dispose() async {
    if (!await doesForegroundExist()) return;

    await _uptimeMutex.protect(() async {
      await _controlChannelToKotlin.send(_controlMessageDispose);
      final stopwatch = Stopwatch()..start();
      const timeout = Duration(milliseconds: 1000);

      while (stopwatch.elapsed < timeout) {
        if (!await doesForegroundExist()) return;
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (!await doesForegroundExist()) return;
      throw Exception("[Foreground Kotlin service]: failed to stop in time");
    });
  }

  Future<bool> doesForegroundExist() async {
    final String? result = await _controlChannelToKotlin.send(_controlMessageDoesExist);
    return result == "true";
  }

  // Just semantic wrapper
  Future<void> ensureStopped() async {
    await dispose();
  }

  void setMessageHandler(void Function(String)? handler) => _messageHandlerCallback = handler;

  // --------------------------------------------------------------

  Future<String> _messageHandler(String? message) async {
    if (message != null) _messageHandlerCallback?.call(message);
    return _noResponse;
  }

  Future<String?> sendMessage(String message) async {
    return await _channelToForeground.send(message);
  }

  Future<String?> sendMessageJSON(Map<String, dynamic> message) async {
    return await sendMessage(jsonEncode(message));
  }
}
