import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wp_player/services/foreground_kotlin/foreground/foreground_kotlin_isolate.dart';

const String _foregroundDartToKotlinForegroundChannel = 'kotlin_foreground_to_dart_foreground';
const String _noResponse = "";

const BasicMessageChannel<String> _channelToDartMain = BasicMessageChannel<String>(
  _foregroundDartToKotlinForegroundChannel,
  StringCodec(),
);

// --------------------------------------------------

ForegroundIsolate? _foregroundIsolate;

void realKotlinForegroundEntryPointMain() {
  WidgetsFlutterBinding.ensureInitialized();

  _foregroundIsolate = ForegroundIsolate((Map<String, dynamic> message) async {
    await _sendMessageToDartMain(jsonEncode(message));
  });

  _channelToDartMain.setMessageHandler(_messageHandler);
}

// --------------------------------------------------
// Channel to Main Dart

Future<String> _messageHandler(String? message) async {
  if (message == null) return _noResponse;

  _foregroundIsolate?.onReceiveData(message);
  return _noResponse;
}

Future<String?> _sendMessageToDartMain(String message) async {
  return await _channelToDartMain.send(message);
}

// --------------------------------------------------
