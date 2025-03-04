//
//  PlaybackViewController.swift
//  Wavepaths Player
//
//  Created by Mariusz Kukawski on 30/04/2024.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import UIKit

func timeString(timeSecs: UInt64) -> String {
        let hour = timeSecs / 3600
        let minute = timeSecs / 60 % 60
        let second = timeSecs % 60

        // return formated string
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }

class PlaybackViewController: UIViewController {
    @IBOutlet weak var bufferInfoLabel: UILabel!

    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var sessionNameLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!

    @IBOutlet weak var VersionLabel: UILabel!
    @IBOutlet weak var sessionStatusLabel: UILabel!
    
    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet weak var advanceToMainPhaseButton: UIButton!
    private var refreshPlaybackInfoTimer: Timer?
    @IBOutlet weak var scanQRCodeButton: UIButton!
    
    @IBOutlet weak var signInAsATherapistButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshPlaybackInfoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: self.refreshPlaybackUIData)
        playPauseButton.setTitle(" ", for: .normal)
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        
        if (appVersion != nil && buildNumber != nil) {
            VersionLabel.text = "\(appVersion!) (\(buildNumber!))"
        }
        
    }
    
    @IBAction func onVolumeChange(_ sender: Any) {
        AssetPlaybackManagerFactory.shared.getManager().setVolume(volume: volumeSlider.value)
    }
    
    @IBAction func onPlayPauseClick(_ sender: Any) {
        let playbackManager = AssetPlaybackManagerFactory.shared.getManager()
        if (playbackManager.isPlayingNow) {
            playbackManager.pause()
        } else {
            playbackManager.resume()
        }
    }
    
    @IBAction func onStartSessionClick(_ sender: Any) {
        AssetPlaybackManagerFactory.shared.getManager().startSession()
    }
    
    @IBAction func onSignInAsATherapistClick(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://guide.wavepaths.com")!, options: [:], completionHandler: nil);
    }
    
    @IBAction func onAdvanceToMainPhaseClick(_ sender: Any) {
        AssetPlaybackManagerFactory.shared.getManager().advanceFromPrelude()
    }
    
    func refreshPlaybackUIData(timer: Timer) {
        let playbackManager = AssetPlaybackManagerFactory.shared.getManager()
        let secondsBuffered = UInt64(playbackManager.bufferedTimeSecs.rounded())
        //let fullminutesBuffered = round( Double(secondsBuffered) / 60)
        //let secondsInAMinuteBuffered = secondsBuffered % 60

        bufferInfoLabel.text = timeString(timeSecs: secondsBuffered) //"\(fullminutesBuffered)m  \(secondsInAMinuteBuffered) s"
        
        let tick = playbackManager.tick
        let totalSeconds = (tick?.sessionDuration ?? UInt64(0)) / UInt64(1000)
        if (tick?.sessionState == .mainPhase || tick?.sessionState == .pause) {
            let secondsElapsed = playbackManager.effectiveTimeSecs
            //let fullMinutesElapsed = round( Double(secondsElapsed) / 60)
            //let secondsInAMinuteElapsed = round()
            
            elapsedTimeLabel.text = timeString(timeSecs: UInt64(secondsElapsed))
        } else {
            elapsedTimeLabel.text = "--"
        }
        
        
        totalDurationLabel.text = timeString(timeSecs: totalSeconds)
        let session = playbackManager.session
        if (session?.variableInputs.name != nil && session!.variableInputs.name!.count > 0) {
            sessionNameLabel.text = session?.variableInputs.name
        } else if (session?.score.name != nil && session!.score.name!.count > 0) {
            sessionNameLabel.text = session?.score.name
        } else {
            sessionNameLabel.text = "--"
        }

        playPauseButton.setTitle("", for: .normal)
        if (playbackManager.isPlayingNow) {
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: [])
        } else {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: [])
        }
        
        setPlaybackButtonsVisibility()
    }
    
    private func setPlaybackButtonsVisibility() {
        let playbackManager = AssetPlaybackManagerFactory.shared.getManager()
        let session = playbackManager.session
        
        if (session != nil) {
            scanQRCodeButton.isHidden = true
            signInAsATherapistButton.isHidden = true
        } else {
            //scanQRCodeButton.isHidden = false
            //TODO: scan QR codes
            scanQRCodeButton.isHidden = true
            
            //TODO : remove as not approved by Apple review
            signInAsATherapistButton.isHidden = true

        }
        
        playPauseButton.isHidden = true
        startSessionButton.isHidden = true
        advanceToMainPhaseButton.isHidden = true

        if (playbackManager.tick?.sessionState == .postlude) {
            sessionStatusLabel.text = "Session has ended, playing postlude music"
            return
        }
        
        if (playbackManager.tick?.sessionState == .ended) {
            sessionStatusLabel.text = "Session has ended"
            return
        }
        
        if (playbackManager.tick?.sessionState == .pause) {
            sessionStatusLabel.text = "Session is paused"
            playPauseButton.isHidden = !playbackManager.mayControlPlayback
            return
        }

        if (playbackManager.tick?.sessionState == .mainPhase) {
            playPauseButton.isHidden = !playbackManager.mayControlPlayback
            sessionStatusLabel.text = "Streaming session..."
            return
        }
        
        if (playbackManager.tick?.sessionState == .prelude) {
            advanceToMainPhaseButton.isHidden = !playbackManager.mayControlPlayback
            sessionStatusLabel.text = "Playing prelude music..."
            return
        }
        
        if (!playbackManager.sessionInitialized && session != nil) {
            startSessionButton.isHidden = !playbackManager.mayControlPlayback
            sessionStatusLabel.text = playbackManager.mayControlPlayback ? "" : "Playback is being controlled by your Care-Provider..."
            return
        }
    }

}
