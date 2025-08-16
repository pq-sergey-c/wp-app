import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wp_player/providers/popup/types/popup_content.dart';
import 'package:wp_player/utils/logger/logger.dart';

typedef RequestNotificationPermissionYesNoPopupCallback =
    Future<bool> Function({required PopupContent content, required String yesText, required String noText});

class RequestNotificationPermissions {
  /// Should be called at the beginning of the app, to allow not UI elements to make notification permission request
  static void setup(RequestNotificationPermissionYesNoPopupCallback addPopupYesNo) {
    _addPopupYesNo = addPopupYesNo;
  }

  static RequestNotificationPermissionYesNoPopupCallback? _addPopupYesNo;

  // ---------------------------------------------------------

  /// On Android 13+ works in explicit flow.
  /// On older OS will show popup only if user manually disabled notifications,
  /// and will prompt user (if agreed) to open settings and change permissions
  static Future<bool> requestPermissionsToStartForegroundService() async {
    final PermissionStatus notificationPermissions = await Permission.notification.status;
    if (notificationPermissions.isGranted) return true;

    if (notificationPermissions.isPermanentlyDenied) {
      await _requestUpdateSettingAndAppReload();

      // in this flow - user should explicitly reload app
      // to start using ForegroundService after change of settings
      return false;
    }

    return await _requestPermissionToUseNotifications();
  }

  static Future<bool> isGrantedPermissionsToStartForegroundService() async {
    final bool isGranted = (await Permission.notification.status).isGranted;
    if (!isGranted) {
      logConsole.i("No permission to start foreground service");
    }
    return isGranted;
  }

  // ---------------------------------------------------------

  static Future<void> _requestUpdateSettingAndAppReload() async {
    if (_addPopupYesNo == null) {
      logConsole.f(_noGlobalNavigatorContext);
      return;
    }

    final bool isUserOkWithOpeningSettings = await _addPopupYesNo!(
      yesText: _now,
      noText: _maybeLatter,
      content: PopupContent.text(title: _openSettingsTitle, message: const TextSpan(text: _messageToOpenSettings)),
    );
    if (!isUserOkWithOpeningSettings) return;

    await openAppSettings();
  }

  static Future<bool> _requestPermissionToUseNotifications() async {
    if (_addPopupYesNo == null) {
      logConsole.f(_noGlobalNavigatorContext);
      return false;
    }

    final bool isUserOkWithPermissions = await _addPopupYesNo!(
      yesText: _now,
      noText: _maybeLatter,
      content: PopupContent.text(
        title: _notificationRequiredTitle,
        message: const TextSpan(text: _messageWhenPermissionsAreStillGrantable),
      ),
    );

    if (!isUserOkWithPermissions) return false;

    final bool isGranted = await Permission.notification.request().isGranted;
    if (isGranted) return true;

    // if denied request update of settings and use fallback
    await _requestUpdateSettingAndAppReload();
    return false;
  }

  // ---------------------------------------------------------

  static const String _noGlobalNavigatorContext =
      "Incoherent state in RequestNotificationPermission - yes/no popup callback is missing";

  static const String _now = "Now";
  static const String _maybeLatter = "Maybe latter";

  static const String _notificationRequiredTitle = "Notification Permission Required";
  static const String _messageWhenPermissionsAreStillGrantable =
      "Wavepath needs notification permission to enable background music streaming"
      " and provide controls on your lock screen and notification bar."
      " Otherwise, background streaming might be interrupted on some devices";

  static const String _openSettingsTitle = "Enable Notifications in Settings";
  static const String _messageToOpenSettings =
      "Wavepath needs notification permission for background music streaming and controls on your lock screen and notification bar."
      " This permission is currently disabled."
      " Please manually enable it in your device's settings under 'Notifications' or 'Permissions' for Wavepath";
}
