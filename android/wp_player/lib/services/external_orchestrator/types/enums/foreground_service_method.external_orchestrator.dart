enum ForegroundServiceMethod {
  init("init"),
  start("start"),
  startSessionEarly("startSessionEarly"),
  broadcastUserAdvanceFromPrelude("broadcastUserAdvanceFromPrelude"),
  resume("resume"),
  pause("pause"),
  dispose("dispose");

  final String value;

  const ForegroundServiceMethod(this.value);

  static ForegroundServiceMethod? fromString(final String value) {
    try {
      return ForegroundServiceMethod.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}
