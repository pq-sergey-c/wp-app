import 'package:flutter/cupertino.dart';
import 'package:wp_player/types/session/session_info/fragments/atmosphere_color.dart';
import 'package:wp_player/types/session/session_info/fragments/emotional_intensity.dart';
import 'package:wp_player/types/session/session_render_type/session_render_type.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

@immutable
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

  /// has value only when session has setup needed to have it (e.g [sessionType] or what [userRole] is it)
  final Uri? providerControlUri;

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
    required this.providerControlUri,
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
        "The music of this session is created by your provider either for playback-only use (Pre-recorded)",
    UserRole.provider:
        "The music of this session is created by your provider either for playback-only use (Pre-recorded)",
  },
  SessionRenderType.predictiveComposed: {
    UserRole.listener: "The music of this session is created by your provider in real-time (Live)",
    UserRole.provider: "The music of this session is created by your provider in real-time (Live)",
  },
  SessionRenderType.realTime: {
    UserRole.listener: "The music of this session is created by your provider in real-time (Real time)",
    UserRole.provider: "The music of this session is created by your provider in real-time (Real time)",
  },
};
