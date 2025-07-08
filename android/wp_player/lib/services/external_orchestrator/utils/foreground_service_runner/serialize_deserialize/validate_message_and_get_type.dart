String foregroundServiceValidateMessageAndGetType(dynamic json) {
  if (json is! Map<String, dynamic>) {
    throw StateError(
      "Incoherent state in External orchestrator (foreground service),"
      " got incorrect type of message: ${json.runtimeType}. Message: $json",
    );
  }

  final type = json["type"];
  if (type is! String) {
    throw StateError(
      "Incoherent state in External orchestrator (foreground service),"
      " unknown message type: $type",
    );
  }

  return type;
}
