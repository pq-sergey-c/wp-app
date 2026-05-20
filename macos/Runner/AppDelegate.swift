import Cocoa
import FlutterMacOS
import app_links

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    super.applicationWillFinishLaunching(notification)
    // app_links registers its kAEGetURL Apple Event handler in super above
    // (via FlutterAppLifecycleDelegate.handleWillFinishLaunching).
    // This replaces NSApplication's default handler, so application(_:open:) is never called.
    // We re-register here to intercept the event ourselves: activate the window,
    // then forward the URL directly to app_links.
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleURLEvent(_:withReply:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )
  }

  @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
    NSApp.activate(ignoringOtherApps: true)
    for window in NSApp.windows {
      if window.isMiniaturized { window.deminiaturize(nil) }
      window.makeKeyAndOrderFront(nil)
      break
    }
    if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue {
      AppLinks.shared.handleLink(link: urlString)
    }
  }
}
