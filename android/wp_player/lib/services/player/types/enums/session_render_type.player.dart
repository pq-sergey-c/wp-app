enum SessionRenderType {
  realTime("realTime"),
  preRendered("preRendered"),
  predictiveComposed("predictiveComposed");

  final String value;
  const SessionRenderType(this.value);

  static SessionRenderType? fromString(final String value) {
    try {
      return SessionRenderType.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }

  String get getReadableName {
    final String? name = _sessionRenderTypeReadableNameByRenderTypeMap[this];
    if (name == null) throw StateError("No readable name is found for the current SessionRenderType $value");
    return name;
  }
}

const Map<SessionRenderType, String> _sessionRenderTypeReadableNameByRenderTypeMap = {
  SessionRenderType.preRendered: 'Pre-rendered',
  SessionRenderType.predictiveComposed: 'Predictive composed',
  SessionRenderType.realTime: 'Real time',
};
