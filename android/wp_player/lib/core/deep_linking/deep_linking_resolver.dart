import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/core/deep_linking/deep_linking_provider.dart';
import 'package:wp_player/core/navigation/navigation_key.dart';
import 'package:wp_player/utils/logger/logger.dart';

class DeepLinkingResolver extends HookConsumerWidget {
  final Widget child;

  const DeepLinkingResolver({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      final StreamSubscription<Uri> linkingStream = AppLinks().uriLinkStream.listen((uri) {
        logConsole.i('[DeepLinking]: $uri');
        ref.read(deepLinkingProvider.notifier).changeLink(uri.toString());

        final BuildContext? navigationalContext = getNavigatorKey().currentState?.context;

        if (navigationalContext == null || !navigationalContext.mounted) {
          logConsole.f('[DeepLinking]: failed to navigate to correct page');
          return;
        }

        navigationalContext.go('/');
      });

      return linkingStream.cancel;
    }, []);
    return child;
  }
}
