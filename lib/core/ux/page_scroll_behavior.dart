import 'dart:ui';

import 'package:flutter/material.dart';

class _WindowsScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

final ScrollBehavior pageScrollBehaviorWithoutScrollBar = _WindowsScrollBehavior().copyWith(scrollbars: false);
final ScrollBehavior pageScrollBehaviorWithScrollBar = _WindowsScrollBehavior().copyWith(scrollbars: true);
