import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';
import 'package:wp_player/types/session/session_render_type.player.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class SessionInfo {
  final String id;

  final String title;
  final SessionRenderType sessionType;
  final String artist;
  final String deviceInfo;
  final String imageUrl;

  final EmotionalIntensity emotionalIntensity;
  final TriadOfAtmosphereColors atmosphereColors;

  final UserRole userRole;

  const SessionInfo({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.artist,
    required this.deviceInfo,
    required this.imageUrl,
    required this.emotionalIntensity,
    required this.atmosphereColors,
    required this.userRole,
  });

  String get sessionDescription {
    final descriptionMap = _sessionTypeAndUserRoleToDescriptionMap[sessionType];
    if (descriptionMap == null) {
      throw StateError("Failed to find session descriptions-userRole map for session type - ${sessionType.name}");
    }
    final description = descriptionMap[userRole];
    if (description == null) {
      throw StateError("Failed to find session description for user role - ${userRole.value}");
    }
    return description;
  }
}

const Map<SessionRenderType, Map<UserRole, String>> _sessionTypeAndUserRoleToDescriptionMap = {
  SessionRenderType.preRendered: {
    UserRole.listener:
        "This app is for music-streaming only. "
        "The music of this is created by your provider either for playback-only/offline use, "
        "or is a recording of a past session (Pre-recorded)",
    UserRole.provider:
        "This app is for music-streaming only. "
        "The music of this is created by your provider either for playback-only/offline use, "
        "or is a recording of a past session (Pre-recorded)",
  },
  SessionRenderType.predictiveComposed: {
    UserRole.listener:
        "This app is for music-streaming only. The music of this session is created by your provider "
        "in real-time (Live).",
    UserRole.provider:
        "This app is for music-streaming only. The session music is created in real-time (Live), "
        "with advanced controls accessible in your browser",
  },
  SessionRenderType.realTime: {
    UserRole.listener:
        "This app is for music-streaming only. The music of this session is created by your provider "
        "in real-time (Real time).",
    UserRole.provider:
        "This app is for music-streaming only. The session music is created in real-time (Real time), "
        "with advanced controls accessible in your browser",
  },
};
