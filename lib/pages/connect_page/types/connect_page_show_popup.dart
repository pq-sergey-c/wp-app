typedef ConnectPageCloseLoadingPopupCallback = void Function();
typedef ConnectPageShowLoadingPopupCallback = ConnectPageCloseLoadingPopupCallback Function();

typedef ConnectPageShowNotificationPopup = Future<void> Function({required String correctnessOf});
