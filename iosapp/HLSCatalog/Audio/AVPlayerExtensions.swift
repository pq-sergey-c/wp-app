//
//  AVPlayerExtensions.swift
//  AVPlayerFade
//
//  Created by Evandro Harrison Hoffmann on 21/05/2020.
//  Copyright © 2020 It's Day Off. All rights reserved.
//

import AVFoundation

class AVPlayerItemSeekable : AVPlayerItem {
    let name: String
    init(name: String, asset: AVAsset) {
        self.name = name
        
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        print("Init AVPlayerItem \(name) \(asset)")
        preferredForwardBufferDuration = 15 * 60
        canUseNetworkResourcesForLiveStreamingWhilePaused = true
        automaticallyPreservesTimeOffsetFromLive = false
        //attempt to always start from the beginning
        configuredTimeOffsetFromLive = CMTime.invalid //CMTimeMakeWithSeconds(99999999, preferredTimescale: 1)
        print("AVPlayerItem initial Status \(name): \(statusToString(newStatus: status))")
        self.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
    }

    
    func statusToString(newStatus: AVPlayerItem.Status) -> String {
        var newStatusString = ""
        if (newStatus == .failed) {
            newStatusString = "failed"
        } else if (newStatus == .readyToPlay) {
            newStatusString = "readyToPlay"
        } else {
            newStatusString = "unknown"
        }
        return newStatusString
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerItem {
            switch keyPath{
            case #keyPath(AVPlayerItem.status):
                print("Change in AVPlayerItem.\(keyPath!) \(name) to \(statusToString(newStatus: status))")
//            case #keyPath(@objc property AVPlayerItem.playbackStalledNotification):
//                print("AVPlayerItem.\(keyPath!) (\(name)) triggered playbackStalledNotification")
//            case #keyPath(AVPlayerItem.automaticallyPreservesTimeOffsetFromLive):
//                print("AVPlayerItem.\(keyPath!) (\(name)) triggered playbackStalledNotification")
            case .none:
                print(".none")
            case .some(_):
                print(".some")
            }
        }
    }
                      
}

class AVPlayerFadeable : AVPlayer {
    let playerName: String
    init(name: String) {
        self.playerName = name
        
        super.init()
        self.automaticallyWaitsToMinimizeStalling = false
    }
    
    override func play() {
        print("play() for \(self.playerName)")

        super.play()
    }
    
    override func playImmediately(atRate rate: Float) {
        print("playImmediately() for \(self.playerName)")

        super.playImmediately(atRate: rate)
    }
    
    override func pause() {
        print("pause() for \(self.playerName)")
        super.pause()
    }
        
    var volumeTimer : Timer?
    var completion: ((_ player: AVPlayerFadeable) -> Void)?
    
    func fadeVolume(to: Float, duration: Float, completion: ((_ player: AVPlayerFadeable) -> Void)? = nil) {
        if volumeTimer != nil {
            print("Invalidating volume timer for \(self.playerName) old to \(to)")
            volumeTimer?.invalidate()
            volumeTimer = nil
            self.completion?(self)
        }
        self.completion = completion

        let from = self.volume
        
        // 1. Set Initial volume
        volume = from
        
        // 2. There's no point in continuing if target volume is the same as initial
        guard from != to else { return }
        
        // 3. We define the time interval the interaction will loop into (fraction of a second)
        let interval: Float = 0.05
        // 4. Set the range the volume will move
        let range = to-from
        // 5. Based on the range, the interval and duration, we calculate how big is the step we need to take in order to reach the target in the given duration
        let step = (range*interval)/duration
        
        // internal function whether the target has been reached or not
        func reachedTarget() -> Bool {
            // volume passed max/min
            guard volume >= 0, volume <= 1 else {
                volume = to
                return true
            }
            
            // checks whether the volume is going forward or backward and compare current volume to target
            if to > from {
                return volume >= to
            }
            return volume <= to
        }
        
        // 6. We create a timer that will repeat itself with the given interval
        print("Setting volume timer for \(self.playerName) to \(to)")
        volumeTimer = Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true, block: { [weak self] (timer) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // 7. Check if we reached the target, otherwise we add the volume
                if !reachedTarget() {
                    // note that if the step is negative, meaning that the to value is lower than the from value, the volume will be decreased instead
                    self.volume += step
                } else {
                    timer.invalidate()
                    self.volumeTimer = nil
                    print("Volume completion for \(self.playerName) to \(to)")

                    self.completion?(self)
                    self.completion = nil
                }
            }
        })
    }
}
