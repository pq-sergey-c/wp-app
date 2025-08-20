import 'package:wp_player/services/player.native_lib/types/native_message.native_lib.dart';

/// Coupled with player.native_lib service
///   Uses respondOnNetworkRequest (which is access via singleton)
///   when networkRequest completes
abstract class INetworkService {
  Future<void> onNetworkRequest(WpDataRequest data);
  Future<void> onNetworkCancel(WpDataCancelRequest data);

  // Future<void> requestStartPlaying(SessionInfo sessionInfo); // CONTINUE: 3 I suppose if to add this one here might be somewhat a solution (though it might be better to make separated networkServices if we would need more stuff)
}
