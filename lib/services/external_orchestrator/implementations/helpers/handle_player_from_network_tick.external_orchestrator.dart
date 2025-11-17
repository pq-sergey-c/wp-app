import 'package:wp_player/services/external_orchestrator/types/enums/network_session_state.external_orchestrator.dart';
import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/player.native_lib/player.native_lib.dart';
import 'package:wp_player/services/player.native_lib/types/phase.native_lib.dart';
import 'package:wp_player/services/player/player.service.dart';

void externalOrchestratorHandlePlayerStateFromTick(final NetworkTick tick) {
  final isConnectionInterrupted = PlayerService().isConnectionInterruptedListenable?.value ?? true;
  if (isConnectionInterrupted && tick.sessionState != NetworkSessionState.connectionEstablished) {
    return;
  }

  switch (tick.sessionState) {
    case NetworkSessionState.pause:
      NativeLibraryPlayer().stop();
    case NetworkSessionState.prelude:
      if (NativeLibraryPlayer().lastSetPhase.value != WpPhase.wpPhasePre) {
        NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhasePre, at: Duration.zero);
      }
      NativeLibraryPlayer().start();
    case NetworkSessionState.mainPhase:
      NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhaseSession, at: tick.effectiveTime);
      NativeLibraryPlayer().start();
    case NetworkSessionState.postlude || NetworkSessionState.ended:
      // postlude isn't used anymore, change in API - consider removing
      // due to change in API ended now works as postlude (date of dart client change: 12 November 2025)
      if (NativeLibraryPlayer().lastSetPhase.value != WpPhase.wpPhasePost) {
        NativeLibraryPlayer().changePhaseTo(WpPhase.wpPhasePost, at: Duration.zero);
      }
      NativeLibraryPlayer().start();
    case NetworkSessionState.planned:
      // do nothing
      break;
    case NetworkSessionState.connectionInterrupted:
      PlayerService().reportConnectionIssue();
      NativeLibraryPlayer().stop();
    case NetworkSessionState.connectionEstablished:
      PlayerService().reportConnectionRestored();
  }
}
