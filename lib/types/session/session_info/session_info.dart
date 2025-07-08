import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';

class SessionInfo {
  final String id;

  final String title;
  final String sessionType;
  final String artist;
  final String description;
  final String deviceInfo;
  final String imageUrl;

  final EmotionalIntensity emotionalIntensity;
  final TriadOfAtmosphereColors atmosphereColors;

  const SessionInfo({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.artist,
    required this.description,
    required this.deviceInfo,
    required this.imageUrl,
    required this.emotionalIntensity,
    required this.atmosphereColors,
  });
}
