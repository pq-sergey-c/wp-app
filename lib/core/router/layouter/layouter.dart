import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef RouteBuilder = Widget Function(BuildContext, GoRouterState);
typedef LayoutBuilder = Widget Function(BuildContext, GoRouterState, Widget);

typedef RouteConfig = ({String route, RouteBuilder builder});

/// Top level function of [layouter system] inside which calls to [layouter] are expected (but not restricted to)
List<GoRoute> layouterFinish({required List<RouteConfig> routes}) {
  return routes
      .map(
        (routeEntry) => GoRoute(
          path: routeEntry.route,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: routeEntry.builder(context, state),
          ),
        ),
      )
      .toList();
}

List<RouteConfig> layouter({required List<RouteConfig> routes, LayoutBuilder? layout}) {
  if (layout == null) return routes;

  return routes
      .map(
        (routeEntry) => (
          route: routeEntry.route,
          builder: (context, state) => layout(context, state, routeEntry.builder(context, state)),
        ),
      )
      .toList();
}
