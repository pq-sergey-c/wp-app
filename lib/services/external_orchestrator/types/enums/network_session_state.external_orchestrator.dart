enum NetworkSessionState {
  planned("planned"),
  prelude("prelude"),
  mainPhase("mainPhase"),
  postlude("postlude"),
  ended("ended"),
  pause("pause"),
  connectionInterrupted("connectionInterrupted"),
  connectionEstablished("connectionEstablished");

  final String value;

  const NetworkSessionState(this.value);

  static NetworkSessionState? fromString(final String value) {
    try {
      return NetworkSessionState.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}
