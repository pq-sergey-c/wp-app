import UIKit
import AVFoundation
import Combine

enum DeckPlaying: String, Codable {
    case DeckA, DeckB
}

class HLSAssetPlaybackManager: NSObject, AssetPlaybackManagerProtocol {
            
    weak var delegate: AssetPlaybackDelegate?
    
    private let deckAPlayer = AVPlayerFadeable(name: "DeckA")
    private let deckBPlayer = AVPlayerFadeable(name: "DeckB")
    
    private let preludePostludePlayer = AVPlayerFadeable(name: "Prelude")

    var tick: WPTick?
    
    var freudConnection: FreudConnection?
    
    private var playerItemObserver: NSKeyValueObservation?
    
    private var deckAPlayerObserver: NSKeyValueObservation?
    
    private var perfMeasurements: PerfMeasurements?
    
    private var broadcastState: BroadcastPersistentState?
    
    private var voiceover: Array<VoiceoverStage>?
    
    private var currentDspOffsetMs: UInt64 = 0
    
    var broadcastStateSubscription: AnyCancellable? = nil
    var inboundSessionEventSubscription: AnyCancellable? = nil

    var tickSubscription: AnyCancellable? = nil
        
    var sessionInitialized: Bool = false

    var asset: Asset? {
        willSet {
            unloadAsset()
        }
        
        didSet {
            if let asset = asset {
                let renderType = asset.session?.renderType
                self.ending = false
                self.voiceover = asset.session?.score.voiceover
                if renderType != .preRendered && asset.session != nil {

                    freudConnection = FreudConnectionOnline(
                        broadcastIdentifier: asset.sessionInfo.broadcastIdentifier,
                        freudEnv: asset.sessionInfo.freudEnv,
                        sessionId: asset.session!.id)
                    
                    self.broadcastStateSubscription = freudConnection?.broadcastStatePublisher.sink { [weak self] incomingMessage in
                        guard let self = self else { return }
                        //print("Received event: \(incomingMessage)")
                        if incomingMessage.event == "broadcastStateUpdate" {
                            //print("broadcastStateUpdate")
                            
                            self.broadcastState = incomingMessage.data
                            if !self.initiatedOncePlayback {
                                self.checkReadinessAndPlayIfReady()
                            }
                        } else {
                            //throw NSError(domain: "Wavepaths", code: 1, userInfo: ["message": "broadcastStateUpdate"])
                            print("not supported event")
                        }
                    }
                    self.inboundSessionEventSubscription = freudConnection?.inboundSessionEventPublisher.sink { [weak self] incomingMessage in
                        guard let self = self else { return }
                        //print("Received event: \(incomingMessage)")
                        if incomingMessage.data.event.event == .reviseSessionPlan {
                            //print("reviseSessionPlan")
                            
                            self.voiceover = incomingMessage.data.event.revisedScore.voiceover
                        } else {
                            //throw NSError(domain: "Wavepaths", code: 1, userInfo: ["message": "broadcastStateUpdate"])
                            print("not supported event: \(incomingMessage.data.event.event)")
                        }
                    }
                    
                    self.tickSubscription = freudConnection?.tickPublisher.sink { [weak self] incomingMessage in
                        guard let self = self else { return }
                        //print("Received event: \(incomingMessage)")
                        if incomingMessage.event == "tick" {
                            self.tick = incomingMessage.data
                            self.sessionInitialized = self.tick != nil ? self.tick!.timeSinceInit > 0 : false
                            self.calculateBroadcastElapsedTime()
                            self.checkPreludePostludeAndPlay()
                            self.checkReadinessAndPlayIfReady()
                            self.checkPause();
                        } else {
                            //throw NSError(domain: "Wavepaths", code: 1, userInfo: ["message": "broadcastStateUpdate"])
                            print("not supported event")
                        }
                    }
                    freudConnection?.connect()
                }
                
                self.delegate?.streamPlaybackManager(self, playerCurrentItemDidChange: asset)
                
            } else {
                unloadAsset()
            }
        }
    }

    var session: WPSession? {
        get {
            return asset?.session
        }
    }
    
    func unloadAsset() {
        print("unloadAsset()")
        deckAPlayer.replaceCurrentItem(with: nil)
        deckBPlayer.replaceCurrentItem(with: nil)
        custom1Player.replaceCurrentItem(with: nil)
        custom2Player.replaceCurrentItem(with: nil)

        tick = nil
        broadcastState = nil

        freudConnection?.disconnect()
        freudConnection = nil
        if transitionCheckTimer != nil {
            transitionCheckTimer?.invalidate()
            transitionCheckTimer = nil
        }
        initiatedOncePlayback = false
        ending = false
        isPlayingNow = false
        nextTimelineItemScheduledToLoad = nil
        sessionInitialized = false
        initiatedPreludePostlude = false
        broadcastStateSubscription?.cancel()
        broadcastStateSubscription = nil
        inboundSessionEventSubscription?.cancel()
        inboundSessionEventSubscription = nil
        tickSubscription?.cancel()
        tickSubscription = nil
        broadcastElapsedTimeMs = 0
        broadcastElapsedTimeSecs = 0
        futurePlayerItem = nil

    }
    
    private var initiatedOncePlayback = false
    var isPlayingNow = false
    
    private var transitionCheckTimer: Timer?
    let BROADCAST_STREAMS_FADE_TIME_SECS: UInt64 = 30
    
    func pause() {
        freudConnection?.pause()
    }
    
    func resume() {
        freudConnection?.resume()
    }

    func startSession() {
        freudConnection?.startSessionEarly()
    }
    
    func advanceFromPrelude() {
        freudConnection?.broadcastUserAdvanceFromPrelude()
    }
    
    private func checkPause() {
        if (tick?.sessionState != WPSessionState.pause || !isPlayingNow) {
            return
        }
        
        forcePlaybackPause()
    }
    
    private func forcePlaybackPause() {
        print("forcePlaybackPause()")
        isPlayingNow = false
        
        deckAPlayer.fadeVolume(to: 0, duration: 5, completion: { player in player.pause() })
        deckBPlayer.fadeVolume(to: 0, duration: 5, completion: { player in player.pause() })
        custom1Player.fadeVolume(to: 0, duration: 5, completion: { player in player.pause() })
        custom2Player.fadeVolume(to: 0, duration: 5, completion: { player in player.pause() })

        initiatedOncePlayback = false
        if transitionCheckTimer != nil {
            transitionCheckTimer?.invalidate()
            transitionCheckTimer = nil
        }
        nextTimelineItemScheduledToLoad = nil
        lastVoiceOverStageToLoadAhead1 = nil
        lastVoiceOverStageToPlay1 = nil
        futurePlayerItem = nil

    }
    
    var initiatedPreludePostlude = false
    private func checkPreludePostludeAndPlay() {
        if (tick != nil && tick?.sessionState != WPSessionState.prelude && tick?.sessionState != WPSessionState.postlude ) || initiatedPreludePostlude {
            return
        }
        print("Playing prelude/postlude...")
        initiatedPreludePostlude = true

        
        preludePostludePlayer.volume = 0
        let preludeAudioUrl = Bundle.main.url(forResource: "prelude_postlude_30m", withExtension: "mp3")!

        let preludeItem = AVPlayerItem(asset: AVURLAsset(url: preludeAudioUrl))
        preludeItem.preferredForwardBufferDuration = 60
        preludePostludePlayer.replaceCurrentItem(with: preludeItem)
        let targetVolume = self.gainOfMusicWhileVOPlaying * self.generalVolume
        self.preludePostludePlayer.fadeVolume(to: targetVolume, duration: 1)
        self.preludePostludePlayer.play()
    }

    private var needSeekAfterBuffering = true
    private func checkReadinessAndPlayIfReady() {
        //print("broadcastElapsedTimeSecs: \(broadcastElapsedTimeSecs) sessionState: \(tick?.sessionState)")
        
        if self.tick == nil || broadcastState == nil || asset == nil || initiatedOncePlayback || tick?.sessionState != WPSessionState.mainPhase || ending {
            return
        }
        initiatedOncePlayback = true
        isPlayingNow = true
        
        mainPlayer = deckAPlayer
        futurePlayer = deckBPlayer
        futurePlayerItem = nil
        mainDeckNow = .DeckA

        let timelineSortedDesc = broadcastState!.timeline.sorted(by: {a , b in return b.dspOffset < a.dspOffset})
        let closestTimelineItem = timelineSortedDesc.filter({x in x.dspOffset <= broadcastElapsedTimeMs }).first
        currentDspOffsetMs = closestTimelineItem!.dspOffset
        
        let timeRelativeInSessionSecs = Double(broadcastElapsedTimeSecs) - (Double(closestTimelineItem!.dspOffset) / 1000.00)

        var playingAsset = asset!.urlAsset;
        if (closestTimelineItem!.dspOffset > 0) {
            let FREUD_STREAMS_BASE_URL = asset!.sessionInfo.freudEnv == "dev" || asset!.sessionInfo.freudEnv == "dev-local" ? "freud-streams-dev.wavepaths.com" : "freud-streams.wavepaths.com"

            let initialStreamUrl = "https://\(FREUD_STREAMS_BASE_URL)/streamdata/\(asset!.sessionInfo.broadcastIdentifier)/offset_\(closestTimelineItem!.dspOffset)/stream.m3u8"
            playingAsset = AVURLAsset(url: URL(string: initialStreamUrl)!)
        }
        let deckAPlayerItem = AVPlayerItemSeekable(name: "Initial", asset: playingAsset)

        //TODO this doesnt help with offsets
        //deckAPlayerItem.configuredTimeOffsetFromLive = CMTime.invalid
        deckAPlayer.replaceCurrentItem(with: deckAPlayerItem)
        //deckAPlayer.play()
        needSeekAfterBuffering = true
        
        preludePostludePlayer.fadeVolume(to: 0, duration: 15, completion: { player in
            player.pause()
            self.initiatedPreludePostlude = false
        })
        
        transitionCheckTimer?.invalidate()
        transitionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: self.transitionCheck)
    }
    
    var nextTimelineItemScheduledToLoad: TimelineItem? = nil
    
    var mainPlayer: AVPlayerFadeable? = nil
    var futurePlayer: AVPlayerFadeable? = nil
    var mainDeckNow: DeckPlaying = .DeckA
    
    var ending = false
    
    private let custom1Player = AVPlayerFadeable(name: "Custom1")
    private let custom2Player = AVPlayerFadeable(name: "Custom2")


    private var lastVoiceOverStageToLoadAhead1 : VoiceoverStage?
    private var lastVoiceOverStageToPlay1 : VoiceoverStage?
    var bufferedTimeSecs = Double(0)
    var broadcastElapsedTimeSecs = UInt64(0)
    private var broadcastElapsedTimeMs = UInt64(0)
    
    var effectiveTimeSecs: Double {
        get {
            return Double(broadcastElapsedTimeSecs)
        }
    }

    var mayControlPlayback: Bool {
        get {
            return asset?.session?.canClientStartEarly ?? false
        }
    }
  
    private var futurePlayerItem : AVPlayerItemSeekable?
    private var futureVO2Item : AVPlayerItemSeekable?

    private func createFuturePlayerItem () {
        let FREUD_STREAMS_BASE_URL = self.asset?.sessionInfo.freudEnv == "dev" ? "freud-streams-dev.wavepaths.com" : "freud-streams.wavepaths.com"

        let futureStreamUrl = "https://\(FREUD_STREAMS_BASE_URL)/streamdata/\(asset!.sessionInfo.broadcastIdentifier)/offset_\(nextTimelineItemScheduledToLoad!.dspOffset)/stream.m3u8"
        let urlAsset = AVURLAsset(url: URL(string: futureStreamUrl)!)
        futurePlayerItem = AVPlayerItemSeekable(name: "Offset \(nextTimelineItemScheduledToLoad!.dspOffset)", asset: urlAsset)
        futurePlayer!.replaceCurrentItem(with: futurePlayerItem)
    }
    
    var seekAfterBufferInProgress = false
    
    private func playFutureItemAfterSeekCompleted() {
        futurePlayer!.pause()
        futurePlayer!.play()
        mainPlayer!.fadeVolume(to: 0, duration: Float(BROADCAST_STREAMS_FADE_TIME_SECS), completion: {player in
            player.pause()
        })
        let targetVolume = gainOfMusicWhileVOPlaying * generalVolume
        futurePlayer!.volume = 0
        futurePlayer!.fadeVolume(to: targetVolume, duration: Float(BROADCAST_STREAMS_FADE_TIME_SECS))
        
        let tmpPlayer = mainPlayer
        mainPlayer = futurePlayer
        futurePlayer = tmpPlayer
        mainDeckNow = mainDeckNow == .DeckA ? .DeckB : .DeckA
        currentDspOffsetMs = nextTimelineItemScheduledToLoad!.dspOffset
        futurePlayerItem = nil
        previousSeconds = nil
        
        nextTimelineItemScheduledToLoad = nil
    }
    
    var previousSeconds : Double? = nil
    
    var custom2isPlaying = false
    private func transitionCheck(timer: Timer) {
        if (asset == nil) {
            return
        }
        
        if (ending) {
            print("Session ending")
            return
        }
        
        if (needSeekAfterBuffering && isPlayingNow) {
            print("Checking if ready to play...")
            if (mainPlayer?.currentItem?.status == .readyToPlay ) {
                needSeekAfterBuffering = false
                
//                print("Seeking to ... \(timeRelativeInSessionSecs) secs")
//                deckAPlayerItem.seek(to: CMTimeMake(value: Int64(timeRelativeInSessionSecs), timescale: 1), toleranceBefore: CMTime(value: 0, timescale: 1), toleranceAfter: CMTime(value: 0, timescale: 1))
                
                let timelineSortedDesc = broadcastState!.timeline.sorted(by: {a , b in return b.dspOffset < a.dspOffset})
                //print("timelineSortedDesc: \(timelineSortedDesc)")
                let closestTimelineItem = timelineSortedDesc.filter({x in x.dspOffset <= broadcastElapsedTimeMs }).first
                //print("closestTimelineItem: \(closestTimelineItem)")
                currentDspOffsetMs = closestTimelineItem!.dspOffset
                
                let timeRelativeInSessionSecs = Double(broadcastElapsedTimeSecs) - (Double(closestTimelineItem!.dspOffset) / 1000.00)
                print("timeRelativeInSessionSecs: \(timeRelativeInSessionSecs)")
                
                print("Starting playback...")
                print("Seek to \(timeRelativeInSessionSecs)")
                
                seekAfterBufferInProgress = true
                print("Priming main player to open HLS stream to avoid later HLS back to head")
                mainPlayer!.play()
                mainPlayer!.seek(to: CMTimeMake(value: Int64(timeRelativeInSessionSecs), timescale: 1), toleranceBefore: CMTime(value: 0, timescale: 1), toleranceAfter: CMTime(value: 0, timescale: 1), completionHandler: {seekCompleted in
                    print("Result of seek \(seekCompleted)")
                    self.seekAfterBufferInProgress = false
                    print("Restarting playback after seek")
                    self.mainPlayer!.play()
                });
                
                let targetVolume = self.gainOfMusicWhileVOPlaying * self.generalVolume
                mainPlayer?.fadeVolume(to: targetVolume, duration: 1)
            }
        }
        
        //print("Time control status")
        //dump(self.mainPlayer?.timeControlStatus)
        let currentSeconds = self.mainPlayer!.currentItem!.timebase!.time.seconds
        if (previousSeconds != nil && self.mainPlayer!.timeControlStatus == .playing && previousSeconds == currentSeconds) {
            // Bug in player? It says it's playing but it's not moving forward...
            print("Detected not moving forward - retry play()...")
            mainPlayer!.pause()
            mainPlayer!.play()
        }
        print("Time in stream: \(currentSeconds) ( \(self.mainPlayer?.playerName) )")
        previousSeconds = currentSeconds

        //let reasonForWaitingToPlay = self.mainPlayer?.reasonForWaitingToPlay
        //print("reasonForWaitingToPlay:")
        //print(reasonForWaitingToPlay)
        
        //print("timeControlStatus:")
        //let timeControlStatus = self.mainPlayer?.timeControlStatus
        //if (timeControlStatus == .paused) { print("paused") }
        //else if (timeControlStatus == .playing) { print("playing") }
        //else if (timeControlStatus == .waitingToPlayAtSpecifiedRate) { print("waitingToPlayAtSpecifiedRate") }
        //else if (timeControlStatus == .none) { print("none") }
        //else if (timeControlStatus == nil) { print("nil") }
        //else { print("unknown") }

        calculateMusicBufferSize();

        if self.mainPlayer?.timeControlStatus == .paused && isPlayingNow && self.mainPlayer?.currentItem?.status != nil && self.mainPlayer?.currentItem?.status != .unknown && !seekAfterBufferInProgress {
            print("Recovering paused playback...")
            initiatedOncePlayback = false
        }
                
        //let elapsedInStreamSecs = self.mainPlayer!.currentItem?.currentTime().seconds ?? Double(0)
        
        
        //print("totalBufferSecs: \(mainPlayerTotalBufferSecs), broadcastElapsedTimeSecs: \(broadcastElapsedTimeSecs), elapsedInStreamSecs: \(elapsedInStreamSecs)")

        
        if !ending && (tick?.sessionState == .postlude || tick?.sessionState == .ended) {
            ending = true
            mainPlayer?.fadeVolume(to: 0, duration: 10, completion: { player in player.pause() })
            futurePlayer?.pause()
            return
        }
        
        //print("Checking for transition at \(broadcastElapsedTimeMs)...")
        let nextMaximalOffsetToFadeMs = broadcastElapsedTimeMs + (BROADCAST_STREAMS_FADE_TIME_SECS * 1000)
        let nextLoadCandidate = broadcastState?.timeline.filter({x in x.dspOffset > broadcastElapsedTimeMs && x.dspOffset <= nextMaximalOffsetToFadeMs}).first
        if nextLoadCandidate != nil {
            if nextLoadCandidate!.dspOffset != nextTimelineItemScheduledToLoad?.dspOffset ?? 0 {
                print("Preloading next stream... \(nextLoadCandidate)")
                nextTimelineItemScheduledToLoad = nextLoadCandidate
                futurePlayer!.volume = 0
                createFuturePlayerItem()
            }
        }
        
        if nextTimelineItemScheduledToLoad != nil && futurePlayerItem?.status == .failed {
            print("Future stream load failed, regenerating it")
            createFuturePlayerItem()
        } else if nextTimelineItemScheduledToLoad != nil && nextTimelineItemScheduledToLoad!.dspOffset <= broadcastElapsedTimeMs {
            if (futurePlayerItem?.status == .readyToPlay) {
                print("Future player prime-play() invoke to avoid returning to the head of HLS")
                futurePlayer!.play()
                print("Seek to beginning of the future stream")

                futurePlayer!.seek(to: CMTimeMake(value: Int64(0), timescale: 1), toleranceBefore: CMTime(value: 0, timescale: 1), toleranceAfter: CMTime(value: 0, timescale: 1), completionHandler: { futurePlayerItemSeekResult in
                    print("Seek of future stream with result : \(futurePlayerItemSeekResult)")
                    print("Status of player item after seek: \(self.futurePlayerItem?.status)")
                    print("Position after seek: \(self.futurePlayer!.currentItem!.timebase!.time.seconds)")
                    print("Playing new stream \(self.nextTimelineItemScheduledToLoad)")
                    self.playFutureItemAfterSeekCompleted()
                })
                

                
            } else {
                print("Future stream not loaded yet...")
            }
        }
        
        let voiceOverStagesSortedDesc1 = voiceover?.sorted(by: {a , b in return b.timing.from < a.timing.from})
        let voiceOverStagesSortedAsc1 = voiceover?.sorted(by: {a , b in return a.timing.from < b.timing.from})
        let voiceOverStageToPlay1 = voiceOverStagesSortedDesc1?.filter({ x in
            x.timing.from <= broadcastElapsedTimeSecs &&
            x.timing.to > broadcastElapsedTimeSecs
        }).first
        var voiceOverStageToLoadAhead1 : VoiceoverStage?
        
        if voiceOverStageToPlay1 != nil && lastVoiceOverStageToPlay1?.timing.from != voiceOverStageToPlay1?.timing.from {
            voiceOverStageToLoadAhead1 = voiceOverStageToPlay1
        } else {
            voiceOverStageToLoadAhead1 = voiceOverStagesSortedAsc1?.filter({ x in
                voiceOverStageToPlay1 == nil && x.timing.from > broadcastElapsedTimeSecs
            }).first
        }
        
        let CUSTOM_VOICEOVERS_PREVIEW_BASE_URL = asset?.sessionInfo.freudEnv == "dev" || asset?.sessionInfo.freudEnv == "dev-local" ? "freud-dev-sampledata.wavepaths.com" : "freud-prod-sampledata.wavepaths.com"

        if lastVoiceOverStageToPlay1 == nil && voiceOverStageToLoadAhead1 != nil && voiceOverStageToLoadAhead1?.timing.from != self.lastVoiceOverStageToLoadAhead1?.timing.from {
            print("Loading future vo1")
            print(voiceOverStageToLoadAhead1)
            let futureVO1Url = "https://\(CUSTOM_VOICEOVERS_PREVIEW_BASE_URL)/custom_voiceovers/\(voiceOverStageToLoadAhead1!.fileNameWithoutExtension).mp3"
            
            let futureVO1Item = AVPlayerItem(asset: AVURLAsset(url: URL(string: futureVO1Url)!))
            self.custom1Player.replaceCurrentItem(with: futureVO1Item)
            
            self.lastVoiceOverStageToLoadAhead1 = voiceOverStageToLoadAhead1
        }
        
        if voiceOverStageToPlay1 != nil && lastVoiceOverStageToPlay1?.timing.from != voiceOverStageToPlay1?.timing.from {
            print("Playing vo1")
            print(voiceOverStageToPlay1)
            let offsetSeconds = broadcastElapsedTimeSecs - voiceOverStageToPlay1!.timing.from;
            self.custom1Player.volume = 0
            self.custom1Player.seek(to: CMTimeMake(value: Int64(offsetSeconds), timescale: 1))
            self.custom1Player.fadeVolume(to: 1, duration: 1)
            self.custom1Player.play()

            self.lastVoiceOverStageToPlay1 = voiceOverStageToPlay1
            self.refreshVOGainAdjustedPlayerVolumes();
        }
        
        if lastVoiceOverStageToPlay1 != nil && voiceOverStageToPlay1 == nil {
            print("Stopping vo1")
            print(lastVoiceOverStageToPlay1)
            self.custom1Player.fadeVolume(to: 0, duration: 1)
            
            self.lastVoiceOverStageToPlay1 = nil
            self.refreshVOGainAdjustedPlayerVolumes()
        }
        
        if voiceOverStageToPlay1 != nil &&
            lastVoiceOverStageToPlay1?.timing.from == voiceOverStageToPlay1?.timing.from &&
            (voiceOverStageToPlay1?.musicGain != lastVoiceOverStageToPlay1?.musicGain ||
             voiceOverStageToPlay1?.volume != lastVoiceOverStageToPlay1?.volume){
            print("Updating vo1 volumes")
            self.lastVoiceOverStageToPlay1 = voiceOverStageToPlay1
            self.refreshVOGainAdjustedPlayerVolumes()
        }
        let FREE_VO_INTERVAL_SECS = UInt64(20 * 60)
        let inRangeToStartFreeVO = broadcastElapsedTimeSecs % FREE_VO_INTERVAL_SECS >= 5 && broadcastElapsedTimeSecs % FREE_VO_INTERVAL_SECS < 15
        if (asset!.sessionInfo.freeVOPlayback && inRangeToStartFreeVO && !custom2isPlaying) {
            custom2isPlaying = true
            print("Playing Free account VO on Custom2")
            let futureVO2Url = asset?.sessionInfo.freudEnv == "dev" || asset?.sessionInfo.freudEnv == "dev-local" ? "https://freud-streams-dev.wavepaths.com/fallback/FreeAccountVOTrimmed.mp3" : "https://freud-streams.wavepaths.com/fallback/FreeAccountVOTrimmed.mp3"
            
            let futureVO2Item = AVPlayerItem(asset: AVURLAsset(url: URL(string: futureVO2Url)!))
            custom2Player.replaceCurrentItem(with: futureVO2Item)
            custom2Player.volume = 0
            custom2Player.fadeVolume(to: 1, duration: 1)
            custom2Player.play()
        }
        
        if (asset!.sessionInfo.freeVOPlayback && !inRangeToStartFreeVO) {
            custom2isPlaying = false
        }
    }
    
    private func calculateBroadcastElapsedTime() {
        broadcastElapsedTimeMs = tick?.effectiveTime ?? 0
        broadcastElapsedTimeSecs = broadcastElapsedTimeMs / 1000
    }
    
    private func calculateMusicBufferSize() {
        let elapsedInStreamSecs = mainPlayer!.currentItem?.currentTime().seconds ?? Double(0)
        bufferedTimeSecs = 0
        if mainPlayer?.currentItem != nil {
            for range in mainPlayer!.currentItem!.loadedTimeRanges {
                let startRange = max(range.timeRangeValue.start.seconds, Double(elapsedInStreamSecs))
                let endRange = max(range.timeRangeValue.end.seconds, Double(elapsedInStreamSecs))
                let durationOfCurrentRange = endRange - startRange
                bufferedTimeSecs += durationOfCurrentRange
            }
        }
        //print("Buffer size secs now : \(mainPlayerTotalBufferSecs)")
    }
    
    var gainOfMusicWhileVOPlaying : Float = 1.0
    var generalVolume : Float  = 1.0

    func setVolume(volume: Float) {
        generalVolume = volume
        refreshVOGainAdjustedPlayerVolumes();
    }
    
    private func refreshVOGainAdjustedPlayerVolumes() {
        self.gainOfMusicWhileVOPlaying = self.lastVoiceOverStageToPlay1?.musicGain ?? 1.0;
        self.preludePostludePlayer.fadeVolume(to: self.gainOfMusicWhileVOPlaying * self.generalVolume, duration: 1)
        self.deckAPlayer.fadeVolume(to: self.gainOfMusicWhileVOPlaying * self.generalVolume, duration: 1)
        self.deckBPlayer.fadeVolume(to: self.gainOfMusicWhileVOPlaying * self.generalVolume, duration: 1)
        self.custom1Player.fadeVolume(to: (self.lastVoiceOverStageToPlay1?.volume ?? 1.0) * self.generalVolume, duration: 1)
        self.custom2Player.fadeVolume(to: self.generalVolume, duration: 1)

    }
        
    override init() {
        super.init()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playback,
                                    mode: AVAudioSession.Mode.default,
                                    options: [AVAudioSession.CategoryOptions.mixWithOthers])
        } catch let error as NSError {
            print("Failed to set the audio session category and mode: \(error.localizedDescription)")
        }

        checkPreludePostludeAndPlay()
    }
    
    deinit {
        deckAPlayerObserver?.invalidate()
        unloadAsset()
    }
    
    func setAssetForPlayback(_ asset: Asset?) {
        self.asset = asset
    }
    
    @objc
    func handleTimebaseRateChanged(_ notification: Notification) {
        if CMTimebaseGetTypeID() == CFGetTypeID(notification.object as CFTypeRef) {
            let timebase = notification.object as! CMTimebase
            let rate: Double = CMTimebaseGetRate(timebase)
            perfMeasurements?.rateChanged(rate: rate)
        }
    }

    @objc
    func handlePlaybackStalled(_ notification: Notification) {
       perfMeasurements?.playbackStalled()
    }
}

protocol AssetPlaybackDelegate: class {
    
    func streamPlaybackManager(_ streamPlaybackManager: HLSAssetPlaybackManager, playerCurrentItemDidChange asset: Asset)
}

extension Notification.Name {
    static let TimebaseEffectiveRateChangedNotification = Notification.Name(rawValue: kCMTimebaseNotification_EffectiveRateChanged as String)
}
