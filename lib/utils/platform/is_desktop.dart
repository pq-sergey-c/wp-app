import 'dart:io';

/// Returns true when the app is running on a desktop-class OS.
bool isDesktopPlatform() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

