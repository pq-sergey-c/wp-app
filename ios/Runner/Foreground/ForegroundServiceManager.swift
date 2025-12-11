import Foundation

#if canImport(Flutter)
import Flutter

final class ForegroundServiceManager {
  private var engine: FlutterEngine?
  private var channelToForeground: FlutterBasicMessageChannel?
  private let onMessageFromForeground: (String) -> Void

  var isRunning: Bool { engine != nil }

  init(onMessageFromForeground: @escaping (String) -> Void) {
    self.onMessageFromForeground = onMessageFromForeground
  }

  func start() {
    if engine != nil { return }

  let engine = FlutterEngine(name: "WavepathsForegroundEngine", project: nil, allowHeadlessExecution: true)
  self.engine = engine

  engine.run(withEntrypoint: "kotlinForegroundEntryPointMain", libraryURI: nil)
    GeneratedPluginRegistrant.register(with: engine)

    let channel = FlutterBasicMessageChannel(
      name: "wp_foreground_bridge_foreground",
      binaryMessenger: engine.binaryMessenger,
      codec: FlutterStringCodec.sharedInstance()
    )

    channel.setMessageHandler { [weak self] message, reply in
      guard let message = message as? String else {
        reply("")
        return
      }
      self?.onMessageFromForeground(message)
      reply("")
    }

    channelToForeground = channel
  }

  func stop() {
    channelToForeground?.setMessageHandler(nil)
    channelToForeground = nil

    engine?.destroyContext()
    engine = nil
  }

  func sendToForeground(message: String) {
    if engine == nil {
      start()
    }
    channelToForeground?.sendMessage(message)
  }
}
#endif
