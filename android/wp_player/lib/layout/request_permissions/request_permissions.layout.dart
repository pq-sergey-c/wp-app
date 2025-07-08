import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:wp_player/core/permissions/request_notification_permissions.dart';

class RequestPermissionsLayout extends HookWidget {
  final Widget child;

  const RequestPermissionsLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      unawaited(
        Future.microtask(() async {
          await RequestNotificationPermissions.requestPermissionsToStartForegroundService();
        }),
      );
      return;
    }, []);

    return child;
  }
}
