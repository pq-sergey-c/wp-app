import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wp_player/components/music_player/generated_player_card_for_session/fragments/generated_card_painter.dart';
import 'package:wp_player/types/session/session_info/session_info.dart';
import 'package:wp_player/utils/logger/logger.dart';

class GeneratedPlayerCardForSession extends StatefulWidget {
  const GeneratedPlayerCardForSession({required this.sessionInfo, super.key});

  final SessionInfo sessionInfo;

  @override
  State<GeneratedPlayerCardForSession> createState() => _GeneratedPlayerCardForSessionState();
}

class _GeneratedPlayerCardForSessionState extends State<GeneratedPlayerCardForSession> {
  static ui.Image? fractalNoise;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_loadNoise));
  }

  Future<void> _loadNoise() async {
    if (fractalNoise != null) return;

    try {
      final ByteData data = await rootBundle.load('assets/images/noise/fractal_noise.png');
      final Uint8List bytes = data.buffer.asUint8List();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        fractalNoise = img as ui.Image?;
        if (mounted) setState(() {});
      });
    } on Error catch (error, _) {
      logConsole.f("Failed to load fractal noise image: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: GeneratedCardPainter(
          generatorSeed: widget.sessionInfo.id,
          emotionalIntensity: widget.sessionInfo.emotionalIntensity,
          primaryAtmosphereColor: widget.sessionInfo.atmosphereColors.first,
          secondaryAtmosphereColor: widget.sessionInfo.atmosphereColors.second,
          tertiaryAtmosphereColor: widget.sessionInfo.atmosphereColors.third,
          noise: fractalNoise,
        ),
      ),
    );
  }
}
