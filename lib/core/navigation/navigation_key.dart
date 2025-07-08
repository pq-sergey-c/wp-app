import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

BuildContext? getNavigatorContext() {
  return _navigatorKey.currentContext;
}

GlobalKey<NavigatorState> getNavigatorKey() {
  return _navigatorKey;
}
