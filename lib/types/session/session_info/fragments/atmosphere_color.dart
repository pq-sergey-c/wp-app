import 'package:flutter/material.dart';

enum AtmosphereColor {
  stillness("Stillness"),
  bittersweet("Bittersweet"),
  tension("Tension"),
  vitality("Vitality"),
  silence("Silence");

  final String value;
  const AtmosphereColor(this.value);

  Color get color {
    return switch (this) {
      stillness => const Color(0xFFB5DECC),
      bittersweet => const Color(0xFFB9C7DA),
      vitality => const Color(0xFFFDBF68),
      tension => const Color(0xFFE26460),
      silence => const Color(0xFFFFFFFF),
    };
  }

  static AtmosphereColor? fromString(String value) {
    try {
      return AtmosphereColor.values.firstWhere((e) => e.value == value);
    } catch (e) {
      return null;
    }
  }
}

typedef TriadOfAtmosphereColors = ({AtmosphereColor first, AtmosphereColor second, AtmosphereColor third});
