typedef SelectRolePageCloseLoadingPopupCallback = void Function();
typedef SelectRolePageShowLoadingPopupCallback = SelectRolePageCloseLoadingPopupCallback Function();

typedef SelectRolePageShowNotificationPopup = Future<void> Function({required String correctnessOf});
