import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/core/deep_linking/types/deep_linking_data.dart';

class _DeepLinkingProvider extends Notifier<DeepLinkingData> {
  @override
  DeepLinkingData build() {
    return DeepLinkingData.empty();
  }

  void changeLink(String? newLink) => state = DeepLinkingData(link: newLink);
}

final deepLinkingProvider = NotifierProvider<_DeepLinkingProvider, DeepLinkingData>(_DeepLinkingProvider.new);
