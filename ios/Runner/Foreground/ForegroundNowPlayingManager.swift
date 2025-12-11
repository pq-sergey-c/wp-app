import AVFoundation
import Foundation
import MediaPlayer
#if canImport(UIKit)
import UIKit
import CoreImage
#endif

#if canImport(Flutter)
import Flutter

final class ForegroundNowPlayingManager {
  private let sendControlCommand: (ForegroundServiceMethod) -> Void
  private var isConfigured = false

  private var trackTitle: String?
  private var artistName: String?
  private var playbackDuration: TimeInterval?
  private var elapsedTime: TimeInterval = 0
  private var isPlaying: Bool = true
#if canImport(UIKit)
  private var artwork: MPMediaItemArtwork?
  private var atmosphereColors: [String: String]?
  private var emotionalIntensity: String = "None"
  private var sessionId: String?
#endif

  init(sendControlCommand: @escaping (ForegroundServiceMethod) -> Void) {
    self.sendControlCommand = sendControlCommand
  }

  func startIfNeeded() {
    guard !isConfigured else { return }
    isConfigured = true

    configureAudioSession()
    #if canImport(UIKit)
    DispatchQueue.main.async {
      UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    #endif
    configureRemoteCommands()
  }

  func stop() {
    guard isConfigured else { return }
    isConfigured = false

#if canImport(UIKit)
    artwork = nil
    atmosphereColors = nil
    emotionalIntensity = "None"
    sessionId = nil
#endif

    DispatchQueue.main.async {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      let commandCenter = MPRemoteCommandCenter.shared()
      commandCenter.playCommand.removeTarget(nil)
      commandCenter.pauseCommand.removeTarget(nil)
      commandCenter.togglePlayPauseCommand.removeTarget(nil)
      #if canImport(UIKit)
      UIApplication.shared.endReceivingRemoteControlEvents()
      #endif
    }
  }

  func handleMainMessage(_ message: String) {
    guard let type = ForegroundMessageParser.type(from: message) else { return }
    if type == "init" {
      processInitMessage(message)
    }
  }

  func handleForegroundMessage(_ message: String) {
    guard let type = ForegroundMessageParser.type(from: message) else { return }

    switch type {
    case "setSessionDuration":
      if let duration = ForegroundMessageParser.dataMilliseconds(from: message) {
        playbackDuration = duration
        updateNowPlaying()
      }
    case "setPlaybackTime":
      if let elapsed = ForegroundMessageParser.dataMilliseconds(from: message) {
        elapsedTime = elapsed
        updatePlaybackState()
      }
    case "processNetworkTick":
      processNetworkTick(message)
    case "disposed":
      stop()
    default:
      break
    }
  }

  // MARK: - Processing

  private func processInitMessage(_ message: String) {
    guard let data = ForegroundMessageParser.dataObject(from: message) else { return }

    if let sessionName = data["sessionName"] as? String {
      trackTitle = sessionName
    }
    if let artist = data["artist"] as? String {
      artistName = artist
    }
#if canImport(UIKit)
    sessionId = data["sessionId"] as? String
    emotionalIntensity = (data["emotionalIntensity"] as? String) ?? "None"
    if let atmosphere = data["atmosphereColors"] as? [String: Any] {
      var parsed: [String: String] = [:]
      for key in ["first", "second", "third"] {
        if let value = atmosphere[key] as? String {
          parsed[key] = value
        }
      }
      atmosphereColors = parsed.count == 3 ? parsed : nil
    } else {
      atmosphereColors = nil
    }
    artwork = nil
#endif
    if let durationMs = data["sessionDuration"] as? NSNumber {
      playbackDuration = durationMs.doubleValue / 1000.0
    }

    updateNowPlaying()
  }

  private func processNetworkTick(_ message: String) {
    guard let data = ForegroundMessageParser.dataObject(from: message),
          let stateRaw = data["sessionState"] as? String else {
      return
    }

    switch stateRaw {
    case "pause", "ended":
      isPlaying = false
    default:
      isPlaying = true
    }

    updatePlaybackState()
  }

  // MARK: - Audio session & remote commands

  private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .default, options: [])
      try session.setActive(true, options: [])
    } catch {
      // ignore - session configuration best effort
    }
  }

  private func configureRemoteCommands() {
    DispatchQueue.main.async {
      let commandCenter = MPRemoteCommandCenter.shared()

      commandCenter.playCommand.isEnabled = true
      commandCenter.pauseCommand.isEnabled = true
      commandCenter.togglePlayPauseCommand.isEnabled = true

      commandCenter.playCommand.addTarget { [weak self] _ in
        self?.sendControlCommand(.resume)
        self?.isPlaying = true
        self?.updatePlaybackState()
        return .success
      }

      commandCenter.pauseCommand.addTarget { [weak self] _ in
        self?.sendControlCommand(.pause)
        self?.isPlaying = false
        self?.updatePlaybackState()
        return .success
      }

      commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
        guard let self = self else { return .commandFailed }
        self.isPlaying.toggle()
        self.sendControlCommand(self.isPlaying ? .resume : .pause)
        self.updatePlaybackState()
        return .success
      }
    }
  }

  // MARK: - Now playing updates

  private func updateNowPlaying() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      var nowPlaying = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
      if let title = self.trackTitle {
        nowPlaying[MPMediaItemPropertyTitle] = title
      }
      if let artist = self.artistName {
        nowPlaying[MPMediaItemPropertyArtist] = artist
      }
      if let duration = self.playbackDuration {
        nowPlaying[MPMediaItemPropertyPlaybackDuration] = duration
      }
      nowPlaying[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedTime
      nowPlaying[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1.0 : 0.0
      nowPlaying[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
#if canImport(UIKit)
      if let generatedArtwork = self.generateAlbumCover() {
        nowPlaying[MPMediaItemPropertyArtwork] = generatedArtwork
      } else {
        nowPlaying.removeValue(forKey: MPMediaItemPropertyArtwork)
      }
#endif

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying
      if #available(iOS 13.0, *) {
        MPNowPlayingInfoCenter.default().playbackState = self.isPlaying ? .playing : .paused
      }
    }
  }

  private func updatePlaybackState() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
      info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.elapsedTime
      info[MPNowPlayingInfoPropertyPlaybackRate] = self.isPlaying ? 1.0 : 0.0
#if canImport(UIKit)
  if let generatedArtwork = self.generateAlbumCover() {
    info[MPMediaItemPropertyArtwork] = generatedArtwork
  }
#endif
      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
      if #available(iOS 13.0, *) {
        MPNowPlayingInfoCenter.default().playbackState = self.isPlaying ? .playing : .paused
      }
    }
  }
}

#endif

#if canImport(UIKit) && canImport(Flutter)
private extension ForegroundNowPlayingManager {
  enum CircleType {
    case primary
    case secondary
    case tertiary

    func radiusRange(baseRadius: CGFloat) -> (min: CGFloat, max: CGFloat) {
      switch self {
      case .primary:
        return (baseRadius * 0.7, baseRadius * 0.9)
      case .secondary:
        return (baseRadius * 0.6, baseRadius * 0.8)
      case .tertiary:
        return (baseRadius * 0.5, baseRadius * 0.7)
      }
    }
  }

  func generateAlbumCover() -> MPMediaItemArtwork? {
    if let existing = artwork { return existing }

    guard let atmosphere = atmosphereColors,
          let sessionId = sessionId,
          let primaryName = atmosphere["first"],
          let secondaryName = atmosphere["second"],
          let tertiaryName = atmosphere["third"],
          let primaryColor = color(from: primaryName),
          let secondaryColor = color(from: secondaryName),
          let tertiaryColor = color(from: tertiaryName) else {
      return artwork
    }

    let size = CGSize(width: 256, height: 256)
    let image = renderAlbumImage(
      size: size,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: tertiaryColor,
      seed: sessionId
    )

    let generated = MPMediaItemArtwork(boundsSize: size) { _ in image }
    artwork = generated
    return generated
  }

  func renderAlbumImage(
    size: CGSize,
    primary: UIColor,
    secondary: UIColor,
    tertiary: UIColor,
    seed: String
  ) -> UIImage {
    let rect = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    let image = renderer.image { ctx in
      let context = ctx.cgContext
      let generator = SeededRandom(seed: seed)
      let circlesImage = drawCirclesImage(
        size: size,
        generator: generator,
        colors: [tertiary, secondary, primary]
      )

      context.saveGState()
      context.translateBy(x: 0, y: size.height)
      context.scaleBy(x: 1, y: -1)

      context.setFillColor(UIColor.white.cgColor)
      context.fill(rect)
      context.setFillColor(primary.withAlphaComponent(0.4).cgColor)
      context.fill(rect)

      let sigma = emotionalIntensitySigma(forCanvasRadius: min(size.width, size.height))
      if let blurred = blurredImage(from: circlesImage, sigma: sigma, rect: rect) {
        context.draw(blurred, in: rect)
      } else if let cgImage = circlesImage.cgImage {
        context.draw(cgImage, in: rect)
      }

      context.restoreGState()

      if let noise = ArtworkResources.noisePatternImage() {
        context.saveGState()
        context.setAlpha(0.1)
        context.setFillColor(UIColor(patternImage: noise).cgColor)
        context.fill(rect)
        context.restoreGState()
      }
    }
    return image
  }

  func drawCirclesImage(size: CGSize, generator: SeededRandom, colors: [UIColor]) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)

    return renderer.image { ctx in
      let context = ctx.cgContext
      context.clear(CGRect(origin: .zero, size: size))

      let gridSize = 5
      let baseRadius = min(size.width, size.height) / 2.0
      let circleTypes: [CircleType] = [.tertiary, .secondary, .primary]

      for (index, type) in circleTypes.enumerated() {
        guard index < colors.count else { continue }
        let color = colors[index]
        let cellWidth = size.width / CGFloat(gridSize)
        let cellHeight = size.height / CGFloat(gridSize)
        let xIndex = generator.nextInt(start: 0, endInclusive: gridSize - 1)
        let yIndex = generator.nextInt(start: 0, endInclusive: gridSize - 1)
        let center = CGPoint(
          x: cellWidth * CGFloat(xIndex) + cellWidth / 2.0,
          y: cellHeight * CGFloat(yIndex) + cellHeight / 2.0
        )

        let range = type.radiusRange(baseRadius: baseRadius)
        let radius = generator.nextDouble(start: range.min, end: range.max)
        let circleRect = CGRect(
          x: center.x - radius,
          y: center.y - radius,
          width: radius * 2.0,
          height: radius * 2.0
        )

        context.setFillColor(color.withAlphaComponent(0.8).cgColor)
        context.fillEllipse(in: circleRect)
      }
    }
  }

  func blurredImage(from image: UIImage, sigma: CGFloat, rect: CGRect) -> CGImage? {
    guard sigma > 0 else { return image.cgImage }
    guard let ciImage = CIImage(image: image),
          let filter = CIFilter(name: "CIGaussianBlur") else {
      return image.cgImage
    }
    let clamped = ciImage.clampedToExtent()
    filter.setValue(clamped, forKey: kCIInputImageKey)
    filter.setValue(sigma, forKey: kCIInputRadiusKey)
    guard let blurred = filter.outputImage?.cropped(to: ciImage.extent) else {
      return image.cgImage
    }
    let cropped = blurred.cropped(to: rect)
    return ArtworkResources.ciContext.createCGImage(cropped, from: rect)
  }

  func emotionalIntensitySigma(forCanvasRadius canvasRadius: CGFloat) -> CGFloat {
    switch emotionalIntensity {
    case "Low":
      return canvasRadius * 0.14
    case "Medium":
      return canvasRadius * 0.12
    case "High":
      return canvasRadius * 0.1
    case "Low to High":
      return canvasRadius * 0.2
    case "None":
      return canvasRadius * 0.2
    default:
      return canvasRadius * 0.2
    }
  }

  func color(from name: String) -> UIColor? {
    switch name {
    case "Stillness":
      return color(hex: 0xFFB5DECC)
    case "Bittersweet":
      return color(hex: 0xFFB9C7DA)
    case "Vitality":
      return color(hex: 0xFFFDBF68)
    case "Tension":
      return color(hex: 0xFFE26460)
    case "Silence":
      return color(hex: 0xFFFFFFFF)
    default:
      return nil
    }
  }

  func color(hex: UInt32) -> UIColor {
    let r = CGFloat((hex >> 16) & 0xFF) / 255.0
    let g = CGFloat((hex >> 8) & 0xFF) / 255.0
    let b = CGFloat(hex & 0xFF) / 255.0
    let a = CGFloat((hex >> 24) & 0xFF) / 255.0
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
}
#endif

#if canImport(UIKit) && canImport(Flutter)
private enum ArtworkResources {
  static let ciContext = CIContext(options: nil)
  private static var cachedNoiseBaseImage: UIImage?
  private static var cachedNoisePatternImage: UIImage?
  private static let noiseScaleFactor: CGFloat = 0.2

  static func noisePatternImage() -> UIImage? {
    if let existing = cachedNoisePatternImage {
      return existing
    }
    guard let base = baseNoiseImage() else { return nil }
    let scaledSize = CGSize(
      width: max(base.size.width * noiseScaleFactor, 1),
      height: max(base.size.height * noiseScaleFactor, 1)
    )
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1.0
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)
    let scaled = renderer.image { _ in
      base.draw(in: CGRect(origin: .zero, size: scaledSize))
    }
    cachedNoisePatternImage = scaled
    return scaled
  }

  private static func baseNoiseImage() -> UIImage? {
    if let existing = cachedNoiseBaseImage {
      return existing
    }
    let assetKey = FlutterDartProject.lookupKey(forAsset: "assets/images/noise/fractal_noise.png")
    guard let path = Bundle.main.path(forResource: assetKey, ofType: nil),
          let image = UIImage(contentsOfFile: path) else {
      return nil
    }
    cachedNoiseBaseImage = image
    return image
  }
}

private final class SeededRandom {
  private var state1: UInt64
  private var state2: UInt64
  private static let hashConstant: UInt64 = 0x9E3779B97F4A7C15

  init(seed: String) {
    var hash: UInt32 = 0
    for byte in seed.utf8 {
      hash = ((hash &<< 5) &+ hash) &+ UInt32(byte)
    }
    let seedValue = UInt64(hash)
    state1 = seedValue == 0 ? 1 : seedValue
    let temp = state1 ^ Self.hashConstant
    if temp != 0 {
      state2 = temp
    } else {
      state2 = state1 != 1 ? 1 : 2
    }
  }

  func callAsFunction() -> Double {
    var x = state1
    let y = state2
    state1 = state2
    x ^= (x << 23)
    x ^= (x >> 17)
    x ^= y
    state2 = x &+ y
    return Double(x) / (Double(UInt64.max) + 1.0)
  }

  func nextDouble(start: CGFloat, end: CGFloat) -> CGFloat {
    let a = min(start, end)
    let b = max(start, end)
    return CGFloat(self()) * (b - a) + a
  }

  func nextInt(start: Int, endInclusive: Int) -> Int {
    let a = min(start, endInclusive)
    let b = max(start, endInclusive)
    let value = nextDouble(start: CGFloat(a), end: CGFloat(b + 1))
    return Int(floor(value))
  }
}
#endif
