import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoService {
  DeviceInfoService._internal();

  static final DeviceInfoService _instance = DeviceInfoService._internal();

  factory DeviceInfoService() => _instance;

  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  String? _cachedDeviceName;
  Future<String>? _pendingComputation;

  Future<String> deviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;
    if (_pendingComputation != null) return _pendingComputation!;

    final future = _computeDeviceName();
    _pendingComputation = future;
    final name = await future;
    _cachedDeviceName = name;
    _pendingComputation = null;

    return name;
  }

  Future<String> _computeDeviceName() async {
    try {
      if (kIsWeb) {
        final info = await _deviceInfoPlugin.webBrowserInfo;
        return info.userAgent ?? info.browserName.name;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          final info = await _deviceInfoPlugin.iosInfo;
          return _firstNonEmpty([info.name, info.model, info.utsname.machine]);
        case TargetPlatform.android:
          final info = await _deviceInfoPlugin.androidInfo;
          return _firstNonEmpty([info.model, info.device, info.product]);
        case TargetPlatform.macOS:
          final info = await _deviceInfoPlugin.macOsInfo;
          return _firstNonEmpty([info.computerName, info.hostName]);
        case TargetPlatform.windows:
          final info = await _deviceInfoPlugin.windowsInfo;
          return _firstNonEmpty([info.computerName]);
        default:
          return "Unknown Device";
      }
    } catch (_) {
      // ignored, fall through to default return value
    }

    return "Unknown Device";
  }

  String _firstNonEmpty(
    List<String?> candidates, {
    String fallback = "Unknown Device",
  }) {
    for (final candidate in candidates) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return fallback;
  }
}
