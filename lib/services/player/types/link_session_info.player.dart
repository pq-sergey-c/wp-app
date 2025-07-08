import 'package:wp_player/services/player/types/enums/external_orchestrator_environment.player.dart';

class LinkSessionInfo {
  final String url;
  final String broadcastId;
  final ExternalOrchestratorEnvironment externalOrchestratorEnv;
  final bool withFreeVoiceover;

  const LinkSessionInfo({
    required this.url,
    required this.broadcastId,
    required this.externalOrchestratorEnv,
    required this.withFreeVoiceover,
  });
}
