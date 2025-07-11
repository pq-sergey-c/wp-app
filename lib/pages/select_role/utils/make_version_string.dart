import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

String? makeVersionString(PackageInfo? packageInfo) {
  if (packageInfo == null) return null;

  if (Platform.isWindows) {
    final versionRaw = packageInfo.version.split('.');
    final versionName = versionRaw.sublist(0, 3).join('.');
    final versionCode = versionRaw[3];
    return "v.$versionName ($versionCode)";
  } else {
    // Platform.isAndroid or other
    return "v.${packageInfo.version} (${packageInfo.buildNumber})";
  }
}
