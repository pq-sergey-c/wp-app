import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:wp_player/components/music_player/generated_player_card_for_session/types/circle_type.dart';
import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';
import 'package:wp_player/utils/math/seeded_random.dart';

// TODO: check that there is no regeneration on changing size of window on Windows
class GeneratedCardPainter extends CustomPainter {
  final String generatorSeed;
  final AtmosphereColor primaryAtmosphereColor;
  final AtmosphereColor secondaryAtmosphereColor;
  final AtmosphereColor tertiaryAtmosphereColor;
  final EmotionalIntensity emotionalIntensity;

  GeneratedCardPainter({
    required this.generatorSeed,
    required this.primaryAtmosphereColor,
    required this.secondaryAtmosphereColor,
    required this.tertiaryAtmosphereColor,
    required this.emotionalIntensity,
    required this.noise,
  });

  late SeededRandom generator;
  final ui.Image? noise;

  @override
  void paint(Canvas canvas, Size size) {
    generator = SeededRandom.fromString(generatorSeed);
    final Rect allCanvasRectangle = Offset.zero & size;

    canvas
      ..drawRect(allCanvasRectangle, Paint()..color = const Color(0xFFFFFFFF))
      ..drawRect(allCanvasRectangle, Paint()..color = primaryAtmosphereColor.color.withValues(alpha: 0.4));

    // ---

    final double canvasRadius = min(size.width, size.height);

    canvas.saveLayer(
      allCanvasRectangle,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: emotionalIntensity.getBlurStandardDeviation(canvasRadius: canvasRadius),
          sigmaY: emotionalIntensity.getBlurStandardDeviation(canvasRadius: canvasRadius),
        ),
    );

    drawCircle(canvas, size, CircleType.tertiary, tertiaryAtmosphereColor);
    drawCircle(canvas, size, CircleType.secondary, secondaryAtmosphereColor);
    drawCircle(canvas, size, CircleType.primary, primaryAtmosphereColor);

    canvas.restore();

    // ---

    drawNoise(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GeneratedCardPainter oldDelegate) {
    return primaryAtmosphereColor != oldDelegate.primaryAtmosphereColor ||
        secondaryAtmosphereColor != oldDelegate.secondaryAtmosphereColor ||
        tertiaryAtmosphereColor != oldDelegate.tertiaryAtmosphereColor ||
        emotionalIntensity != oldDelegate.emotionalIntensity ||
        noise != oldDelegate.noise;
  }

  void drawCircle(Canvas canvas, Size size, CircleType type, AtmosphereColor atmosphereColor) {
    // position circle in center of cell in grid of 5x5
    final ({double width, double height}) ceil = (width: size.width / 5, height: size.height / 5);
    final double x = ceil.width * generator.nextInt(start: 0, end: 4) + ceil.width / 2;
    final double y = ceil.height * generator.nextInt(start: 0, end: 4) + ceil.height / 2;
    final center = Offset(x, y);

    final radiusRange = type.getRadiusRange(canvasRadius: min(size.width, size.height));
    final radius = generator.nextDouble(start: radiusRange.minRadius, end: radiusRange.maxRadius);

    final paint = Paint()..color = atmosphereColor.color.withValues(alpha: 0.8);
    canvas.drawCircle(center, radius, paint);
  }

  void drawNoise(Canvas canvas, Size size) {
    if (noise == null) return;

    final noisePaint =
        Paint()..shader = ImageShader(noise!, TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);

    // saveLayer here use only to set opacity of layer
    canvas
      ..saveLayer(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.1))
      ..drawRect(Offset.zero & size, noisePaint)
      ..restore();
  }
}
