enum ForegroundServiceCallback {
  setBroadcastState("setBroadcastState"),
  setSessionDuration("setSessionDuration"),
  setPlaybackTime("setPlaybackTime"),
  setVoiceovers("setVoiceovers"),
  processNetworkTick("processNetworkTick"),
  disposed("disposed"),
  initialized("initialized"),
  log("log");

  final String value;

  const ForegroundServiceCallback(this.value);

  static ForegroundServiceCallback? fromString(final String value) {
    try {
      return ForegroundServiceCallback.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}
