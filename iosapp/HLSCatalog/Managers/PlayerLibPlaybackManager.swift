import Foundation
import Combine

import WpPlayerLibApple

let STREAM_FADE_OUT_TIME: UInt64 = 15000
let LONG_TIME_FROM_NOW: UInt64 = 365 * 24 * 60 * 60 * 1000

class PlayerLibPlaybackManager: NSObject, AssetPlaybackManagerProtocol {
  
    var tick: WPTick?    
    var sessionInitialized: Bool {
        get {
            guard let tick = tick else { return false }
            return tick.timeSinceInit > 0
        }
    }
    var effectiveTimeSecs: Double {
      get {
        guard let tick = tick else { return 0 }
        return Double(tick.effectiveTime) / 1000.0
      }
    }

    
    var sessionInfo: WPSessionInfo?
    var session: WPSession?
    private var voiceovers: Array<VoiceoverStage>?

    private var wpPlayerLib: WpPlayerLibBridge?
    var isPlayingNow: Bool {
        get {
            guard let wpPlayerLib = wpPlayerLib else { return false }
            return wpPlayerLib.isStarted()
        }
    }
    var mayControlPlayback: Bool {
      guard let session = session else { return false }
      let isOffline = session.renderType == .preRendered || session.endTime != nil
      return isOffline ? true : session.canClientStartEarly
    }
    var bufferedTimeSecs: Double {
      guard let wpPlayerLib = wpPlayerLib else { return 0 }
      return Double(wpPlayerLib.getBufferedTime())
    }


    private var freudConnection: FreudConnection?
    private var broadcastStateSubscription: AnyCancellable?
    private var latestBroadcastState: BroadcastPersistentState?
    private var inboundSessionEventSubscription: AnyCancellable?
    private var tickSubscription: AnyCancellable?

    override init() {
      super.init()
    }

    deinit {
      self.disconnect()
    }

    func connect(sessionInfo: WPSessionInfo, session: WPSession) throws {
      print("playerLibPlaybackManager connect()")
      self.disconnect()
      self.sessionInfo = sessionInfo

      let isOffline = session.renderType == .preRendered || session.endTime != nil
      let bufferLookahead = Int64(isOffline ? 10 * 60 * 60 : 20 * 60);
      self.wpPlayerLib = try WpPlayerLibBridge(bufferLookahead: bufferLookahead)
      guard let playerLib = self.wpPlayerLib else {
        throw NSError(domain: "PlayerLibPlaybackManager", code: 1, userInfo: ["message": "Failed to initialize WpPlayerLibBridge"])
      }


      self.session = session
      self.voiceovers = session.score.voiceover

      self.freudConnection = isOffline ?
          FreudConnectionOffline(session: session) :
          FreudConnectionOnline(
            broadcastIdentifier: sessionInfo.broadcastIdentifier,
            freudEnv: sessionInfo.freudEnv,
            sessionId: session.id
          )
      self.broadcastStateSubscription = freudConnection?.broadcastStatePublisher.sink { [weak self] incomingMessage in
          guard let self = self else { return }
          print("playerLibPlaybackManager got broadcastStateUpdate: \(incomingMessage)")
          if incomingMessage.event == "broadcastStateUpdate" {
              self.latestBroadcastState = incomingMessage.data
              self.updateTimeline()
          }
      }
      self.inboundSessionEventSubscription = freudConnection?.inboundSessionEventPublisher.sink { [weak self] incomingMessage in
          guard let self = self else { return }
          print("playerLibPlaybackManager got inboundSessionEvent: \(incomingMessage)")
          if incomingMessage.data.event.event == .reviseSessionPlan {
              self.voiceovers = incomingMessage.data.event.revisedScore.voiceover
              self.updateTimeline()
          }
      }
      self.tickSubscription = freudConnection?.tickPublisher.sink { [weak self] incomingMessage in 
          guard let self = self else { return }
          if incomingMessage.event == "tick" {
              let wasFirstTick = self.tick == nil
              self.tick = incomingMessage.data
              do {
                  switch incomingMessage.data.sessionState {
                  case .pause:
                      try self.wpPlayerLib?.stop()
                  case .prelude:
                      try self.wpPlayerLib?.setPhase(phase: .pre, atTimeInPhase: Int64(incomingMessage.data.timeSinceInit))
                      try self.wpPlayerLib?.start()
                  case .mainPhase:
                      try self.wpPlayerLib?.setPhase(phase: .session, atTimeInPhase: Int64(incomingMessage.data.effectiveTime))
                      try self.wpPlayerLib?.start()
                  case .postlude:
                      try self.wpPlayerLib?.setPhase(phase: .post, atTimeInPhase: Int64(0))
                      try self.wpPlayerLib?.start()
                  case .ended:
                      try self.wpPlayerLib?.stop()
                  default:
                      break
                  }
              } catch {
                  print("Error handling tick: \(error)")
              }
              if wasFirstTick {
                self.updateTimeline()
              }
          }
      }
      freudConnection?.connect()

      self.updateTimeline()
    }

    private func updateTimeline() {
      guard let sessionInfo = self.sessionInfo else { return }
      guard let session = self.session else { return }

      let preludeAudioUrl = Bundle.main.url(forResource: "prelude_postlude_30m", withExtension: "mp3")!
      let preludeStream = WpStream(
        id: "prelude",
        phase: .pre,
        url: preludeAudioUrl.path,
        fromTime: 0,
        toTime: LONG_TIME_FROM_NOW,
        fadeOutTime: STREAM_FADE_OUT_TIME,
        loopContent: true,
        gain: 1.0,
        usesSidechain: false,
        sidechainGain: 0.0
      )
      let postludeStream = WpStream(
        id: "postlude",
        phase: .post,
        url: preludeAudioUrl.path,
        fromTime: 0,
        toTime: LONG_TIME_FROM_NOW,
        fadeOutTime: STREAM_FADE_OUT_TIME,
        loopContent: true,
        gain: 1.0,
        usesSidechain: false,
        sidechainGain: 0.0
      )
      let FREUD_STREAMS_BASE_URL = sessionInfo.freudEnv == "dev" || sessionInfo.freudEnv == "dev-local" ? "freud-streams-dev.wavepaths.com" : "freud-streams.wavepaths.com"

      let streams = if let timelineSorted = latestBroadcastState?.timeline.sorted(by: {a , b in return a.dspOffset < b.dspOffset}) {
        timelineSorted.enumerated().map { index, item in
          WpStream(
            id: item.sessionId,
            phase: .session,
            url: "https://\(FREUD_STREAMS_BASE_URL)/streamdata/\(sessionInfo.broadcastIdentifier)/\(item.sessionId)/stream.m3u8",
            fromTime: item.dspOffset,
            toTime: index == timelineSorted.count - 1 ? LONG_TIME_FROM_NOW : UInt64(timelineSorted[index + 1].dspOffset) + STREAM_FADE_OUT_TIME,
            fadeOutTime: STREAM_FADE_OUT_TIME,
            loopContent: false,
            gain: 1.0,
            usesSidechain: false,
            sidechainGain: 0.0
          )
        }
      } else {
        [
          WpStream(
            id: session.id,
            phase: .session,
            url: "https://\(FREUD_STREAMS_BASE_URL)/streamdata/\(sessionInfo.broadcastIdentifier)/\(session.id)/stream.m3u8",
            fromTime: 0,
            toTime: LONG_TIME_FROM_NOW,
            fadeOutTime: STREAM_FADE_OUT_TIME,
            loopContent: false,
            gain: 1.0,
            usesSidechain: false,
            sidechainGain: 0.0
          )
        ]
      }

      let CUSTOM_VOICEOVERS_PREVIEW_BASE_URL = sessionInfo.freudEnv == "dev" || sessionInfo.freudEnv == "dev-local" ?
        "https://freud-dev-sampledata.wavepaths.com/custom_voiceovers/" :
        "https://freud-prod-sampledata.wavepaths.com/custom_voiceovers/"
      let voStreams = voiceovers?.map { voiceover in
        WpStream(
          id: "vo-\(voiceover.timing.from)-\(voiceover.timing.to)-\(voiceover.fileNameWithoutExtension)",
          phase: .session,
          url: "\(CUSTOM_VOICEOVERS_PREVIEW_BASE_URL)\(voiceover.fileNameWithoutExtension).mp3",
          fromTime: voiceover.timing.from * 1000,
          toTime: voiceover.timing.to * 1000,
          fadeOutTime: 0,
          loopContent: false,
          gain: voiceover.volume ?? 1.0,
          usesSidechain: true,
          sidechainGain: 1.0 - (voiceover.musicGain ?? 1.0)
        )
      } ?? []

      let FREE_VO_INTERVAL_MS = UInt64.Stride(20 * 60 * 1000)
      let freeVoUrl = sessionInfo.freudEnv == "dev" || sessionInfo.freudEnv == "dev-local" ?
        "https://freud-streams-dev.wavepaths.com/fallback/FreeAccountVOTrimmed.mp3" :
        "https://freud-streams.wavepaths.com/fallback/FreeAccountVOTrimmed.mp3"
      let sessionDurationMs = tick?.sessionDuration ?? 0
      let freeVoStreams: [WpStream] = if sessionInfo.freeVOPlayback {
        stride(from: 5000, to: sessionDurationMs, by: FREE_VO_INTERVAL_MS).map { (time: UInt64) in
          WpStream(
            id: "freeVo-\(time)",
            phase: .session,
            url: freeVoUrl,
            fromTime: time,
            toTime: time + 5 * 60 * 1000, // this assumes the free VO is no longer than 5 minutes long
            fadeOutTime: 0,
            loopContent: false,
            gain: 1.0,
            usesSidechain: true,
            sidechainGain: 0.8
          )
        }
      } else {
        []
      }

      let combinedStreams = [preludeStream, postludeStream] + streams + voStreams + freeVoStreams

      print("playerLibPlaybackManager setting streams:")
      for stream in combinedStreams {
          print("  ID: \(stream.id)")
          print("    Phase: \(stream.phase)")
          print("    URL: \(stream.url)")
          print("    From: \(stream.fromTime)ms")
          print("    To: \(stream.toTime)ms")
          print("    Fade out: \(stream.fadeOutTime)ms")
          print("    Loop: \(stream.loopContent)")
          print("    Gain: \(stream.gain)")
          print("    Uses sidechain: \(stream.usesSidechain)")
          print("    Sidechain gain: \(stream.sidechainGain)")
          print("")
      }

      do {
        try self.wpPlayerLib?.setSession(streams: combinedStreams)
      } catch {
        print("Error setting session: \(error)")
      }
    }

    func disconnect() {
      self.tickSubscription?.cancel()
      self.tickSubscription = nil
      self.inboundSessionEventSubscription?.cancel()
      self.inboundSessionEventSubscription = nil
      self.broadcastStateSubscription?.cancel()
      self.broadcastStateSubscription = nil
      self.freudConnection?.disconnect()
      self.freudConnection = nil
      self.wpPlayerLib?.destroy()
      self.wpPlayerLib = nil
    }
  

    func startSession() {
      self.freudConnection?.startSessionEarly()
    }
    
    func advanceFromPrelude() {
      self.freudConnection?.broadcastUserAdvanceFromPrelude()
    }
    
    func resume() {
      self.freudConnection?.resume()
    }
    
    func pause() {
      self.freudConnection?.pause()
    }
    
    func setVolume(volume: Float) {
      self.wpPlayerLib?.setVolume(volume: volume)
    }

     
}
