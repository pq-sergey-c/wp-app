enum EmotionalIntensity {
  low("Low"),
  medium("Medium"),
  high("High"),
  all("Low to High"),
  none("None");

  final String value;

  const EmotionalIntensity(this.value);

  double get circleSizeScale => switch (this) {
    low => 1,
    medium => 1.1,
    high => 1.2,
    all => 1,
    none => 1,
  };

  /// [canvasRadius] = min(canvas.width, canvas.height)
  double getBlurStandardDeviation({required double canvasRadius}) {
    return switch (this) {
      low => canvasRadius * 0.14,
      medium => canvasRadius * 0.12,
      high => canvasRadius * 0.1,
      all => canvasRadius * 0.2,
      none => canvasRadius * 0.2
    };
  }

  static EmotionalIntensity? fromString(String value) {
    try {
      return EmotionalIntensity.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}
