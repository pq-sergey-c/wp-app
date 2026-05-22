import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/services/player/types/link_session_info.player.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';
import 'package:wp_player/utils/data_parse/http_link_parsing/check_translate_http_link_to_player_link.dart';

ExternalOrchestratorEnvironment _externalOrchestratorEnvFromPathParts(List<String> pathParts) {
  const validEnvs = {'dev', 'dev-local', 'prod'};
  final envString = pathParts.firstWhere((part) => validEnvs.contains(part), orElse: () => 'prod');
  return switch (envString) {
    'dev' => ExternalOrchestratorEnvironment.development,
    'dev-local' => ExternalOrchestratorEnvironment.developmentLocal,
    'prod' => ExternalOrchestratorEnvironment.production,
    _ => ExternalOrchestratorEnvironment.production,
  };
}

LinkSessionInfo? sessionServiceParseLink(String link) {
  if (link.startsWith('https://')) {
    final String? translatedLink = checkTranslateHTTPLinkToPlayerLink(link);
    if (translatedLink == null) return null;
    link = translatedLink;
  }

  if (!link.startsWith('wavepaths2://')) return null;

  final uri = Uri.tryParse(link);
  if (uri == null || uri.path.isEmpty) return null;

  final pathParts = uri.path.split('/').where((part) => part.isNotEmpty).toList();

  if (pathParts.isEmpty) return null;

  // ---

  final broadcastId = pathParts.last;
  if (broadcastId.isEmpty) return null;

  final withFreeVoiceOver = pathParts.contains('free');

  final orchestratorEnv = _externalOrchestratorEnvFromPathParts(pathParts);

  final String? roleString = uri.queryParameters['role'];
  final UserRole? userRole = roleString != null ? _userRoleFromString(roleString) : null;

  return LinkSessionInfo(
    broadcastId: broadcastId,
    externalOrchestratorEnv: orchestratorEnv,
    withFreeVoiceover: withFreeVoiceOver,
    userRole: userRole,
  );
}

UserRole? _userRoleFromString(String value) {
  try {
    return UserRole.fromString(value);
  } catch (_) {
    return null;
  }
}
