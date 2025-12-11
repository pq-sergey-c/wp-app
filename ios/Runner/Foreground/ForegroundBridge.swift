import Foundation

#if canImport(Flutter)
import Flutter

final class ForegroundBridge {
  static let shared = ForegroundBridge()

  private var messenger: FlutterBinaryMessenger?
  private var mainChannel: FlutterBasicMessageChannel?
  private var controlChannel: FlutterBasicMessageChannel?
  private var serviceManager: ForegroundServiceManager?
  private var nowPlayingManager: ForegroundNowPlayingManager?

  private init() {}

  func configure(with messenger: FlutterBinaryMessenger) {
    self.messenger = messenger

    let mainChannel = FlutterBasicMessageChannel(
      name: "wp_foreground_bridge_main_isolate",
      binaryMessenger: messenger,
      codec: FlutterStringCodec.sharedInstance()
    )
    mainChannel.setMessageHandler { [weak self] message, reply in
      self?.handleMainMessage(message, reply: reply)
    }
    self.mainChannel = mainChannel

    let controlChannel = FlutterBasicMessageChannel(
      name: "wp_foreground_bridge_control",
      binaryMessenger: messenger,
      codec: FlutterStringCodec.sharedInstance()
    )
    controlChannel.setMessageHandler { [weak self] message, reply in
      self?.handleControlMessage(message, reply: reply)
    }
    self.controlChannel = controlChannel
  }

  // MARK: - Control flow

  private func handleControlMessage(_ message: Any?, reply: @escaping FlutterReply) {
    guard let message = message as? String else {
      reply("")
      return
    }

    switch message {
    case "startForeground":
      startForeground()
      reply("")
    case "doesForegroundExist":
      let exists = serviceManager?.isRunning ?? false
      reply(exists ? "true" : "false")
    case "disposeForeground":
      disposeForeground()
      reply("")
    default:
      reply("")
    }
  }

  private func startForeground() {
    if serviceManager == nil {
      serviceManager = ForegroundServiceManager { [weak self] message in
        self?.forwardForegroundMessage(message)
      }
    }
    if nowPlayingManager == nil {
      nowPlayingManager = ForegroundNowPlayingManager { [weak self] method in
        self?.sendControlCommand(method: method)
      }
    }

    nowPlayingManager?.startIfNeeded()
    serviceManager?.start()
  }

  private func disposeForeground() {
    nowPlayingManager?.stop()
    serviceManager?.stop()

    nowPlayingManager = nil
    serviceManager = nil
  }

  // MARK: - Messaging

  private func handleMainMessage(_ message: Any?, reply: @escaping FlutterReply) {
    guard let message = message as? String else {
      reply("")
      return
    }

    nowPlayingManager?.handleMainMessage(message)
    serviceManager?.sendToForeground(message: message)
    reply("")
  }

  private func forwardForegroundMessage(_ message: String) {
    nowPlayingManager?.handleForegroundMessage(message)
    mainChannel?.sendMessage(message)
  }

  private func sendControlCommand(method: ForegroundServiceMethod) {
    guard let payload = method.serialize() else { return }
    serviceManager?.sendToForeground(message: payload)
  }
}
#endif
