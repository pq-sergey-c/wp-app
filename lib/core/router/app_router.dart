import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wp_player/core/navigation/navigation_key.dart';
import 'package:wp_player/core/router/layouter/layouter.dart';
import 'package:wp_player/core/router/observers/popup_route_observer.dart';
import 'package:wp_player/layout/go_home/go_home.layout.dart';
import 'package:wp_player/layout/popup/popup.layout.dart';
import 'package:wp_player/layout/request_permissions/request_permissions.layout.dart';
import 'package:wp_player/layout/theme_control/theme_control.layout.dart';
import 'package:wp_player/pages/connect_page/connect_page.page.dart';
import 'package:wp_player/pages/learn_more/learn_more.page.dart';
import 'package:wp_player/pages/player/player.page.dart';
import 'package:wp_player/pages/select_role/select_role.page.dart';
import 'package:wp_player/pages/standalone/qr_scanner/qr_scanner.page.dart';
import 'package:wp_player/types/session/user_role/user_role.dart';

// TODO: maybe change layouter to use one shell route - and simulate multilevel layout with only one shell route
// There were a problem with back_tracking/step_back after failed/step_backed QR code

class AppRouter {
  static GoRouter getRouter(WidgetRef ref) {
    // due to ShellRoute library problems - need to add observers to each ShellRoute and root Route
    // (and all should be unique)
    final observers = [PopupRouteObserver(ref)];

    // Use the global navigator key to make navigator accessible from other part of application
    final rootNavigatorKey = getNavigatorKey();

    return GoRouter(
      initialLocation: '/',
      observers: observers,
      navigatorKey: rootNavigatorKey,

      routes: layouterFinish(
        routes: [
          ...layouter(
            layout: (context, state, child) => ThemeControlLayout(child: _popupLayoutFull(child)),
            routes: [
              (route: '/', builder: (context, state) => SelectRolePage()),

              ...layouter(
                layout: (context, state, child) => GoHomeButtonLayout(child: child),
                routes: [
                  (
                    route: '/connect/:role',
                    builder:
                        (context, state) => ConnectPage(userRole: UserRole.fromString(state.pathParameters['role']!)),
                  ),
                  (route: '/learn_more', builder: (context, state) => const LearnMorePage()),
                  (route: '/player', builder: (context, state) => const PlayerPage()),
                ],
              ),
            ],
          ),

          // -----------------------------------------------------------------------------------------
          // special routes
          ...layouter(
            layout: (context, state, child) => _popupLayoutFull(child),
            routes: [(route: '/standalone/scan_qr', builder: (context, state) => const QrScannerPage())],
          ),
        ],
      ),
    );
  }
}

Widget _popupLayoutFull(Widget child) => PopupLayout(child: RequestPermissionsLayout(child: child));
