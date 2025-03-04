protocol AssetPlaybackManagerProtocol {
  var session: WPSession? { get }
  var tick: WPTick? { get }
  var sessionInitialized: Bool { get }
  var isPlayingNow: Bool { get }
  var mayControlPlayback: Bool { get }
  var effectiveTimeSecs: Double { get }
  var bufferedTimeSecs: Double { get }

  func startSession()
  func advanceFromPrelude()

  func resume()
  func pause()
  func setVolume(volume: Float)
}
