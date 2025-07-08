enum WpPhase {
  wpPhaseNone(0),
  wpPhasePre(1),
  wpPhaseSession(2),
  wpPhasePost(3);
  // _wpPhaseCount - is omitted, it seems to be internal value

  final int value;
  const WpPhase(this.value);

  static WpPhase fromInt(int value) {
    return WpPhase.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Invalid WpPhase value: $value'),
    );
  }
}
