enum CircleType {
  primary("primary"),
  secondary("secondary"),
  tertiary("tertiary"),
  none("none");

  final String type;
  const CircleType(this.type);

  /// [canvasRadius] = min(canvas.width, canvas.height)
  ({double minRadius, double maxRadius}) getRadiusRange({required double canvasRadius}) {
    final double baseRadius = canvasRadius / 2;

    return switch (this) {
      primary => (minRadius: baseRadius * 0.7, maxRadius: baseRadius * 0.9),
      secondary => (minRadius: baseRadius * 0.6, maxRadius: baseRadius * 0.8),
      tertiary => (minRadius: baseRadius * 0.5, maxRadius: baseRadius * 0.7),
      none => (minRadius: baseRadius * 0.4, maxRadius: baseRadius * 0.6),
    };
  }
}
