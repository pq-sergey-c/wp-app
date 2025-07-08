import 'package:wp_player/services/external_orchestrator/types/network_tick.external_orchestrator.dart';
import 'package:wp_player/services/player/types/sub_types/session_broadcast_state.player.dart';
import 'package:wp_player/services/player/types/sub_types/voiceover_stage.player.dart';

// internal + external
typedef CallbackSetBroadcastState = void Function(SessionBroadcastState broadcastState);
typedef CallbackSetVoiceovers = void Function(List<VoiceoverStage> voiceovers);
typedef CallbackSetSessionDuration = void Function(Duration sessionDuration);
typedef CallbackSetPlaybackTime = void Function(Duration currentPlayTime);

// internal only
typedef CallbackProcessNetworkTick = void Function(NetworkTick tick);
