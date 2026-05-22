import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

class LinkSessionInfo {
  final String broadcastId;
  final ExternalOrchestratorEnvironment externalOrchestratorEnv;
  final bool withFreeVoiceover;
  final UserRole? userRole;

  const LinkSessionInfo({
    required this.broadcastId,
    required this.externalOrchestratorEnv,
    required this.withFreeVoiceover,
    this.userRole,
  });
}
