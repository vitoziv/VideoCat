//
//  PlayerTestViewController.swift
//  VideoCat
//
//  Created by Vito on 01/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import VIPlayer

class PlayerTestViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var playImmediatelyButton: UIButton!
    
    @IBOutlet weak var avplayerRateLabel: UILabel!
    @IBOutlet weak var timebaseRateLabel: UILabel!
    @IBOutlet weak var timeControlStatusLabel: UILabel!
    @IBOutlet weak var reasonForWaitingToPlayLabel: UILabel!
    @IBOutlet weak var isPlaybackLikelyToKeepUpLabel: UILabel!
    @IBOutlet weak var loadedTimeRangesLabel: UILabel!
    @IBOutlet weak var playbackBufferFullLabel: UILabel!
    @IBOutlet weak var playbackBufferEmptyLabel: UILabel!
    
    
    var player = VIPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeSlider.value = 0
        timeSlider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        timeSlider.isContinuous = false
        
        player.delegate = self

        let playerView = player.playerView
        playerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(playerView, at: 0)
        
        playerView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        playerView.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        
        let url = URL(string: "https://mvvideo5.meitudata.com/56ea0e90d6cb2653.mp4")!
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(playerItem)
    }

    @IBAction func playAction(_ sender: UIButton) {
        player.play()
    }
    @IBAction func pauseAction(_ sender: UIButton) {
        player.pause()
    }
    @IBAction func playImmediatelyAction(_ sender: UIButton) {
        player.player.playImmediately(atRate: 1.0)
    }
    
    @objc func sliderValueChanged(sender: UISlider) {
        player.seek(to: Double(sender.value), completion: { (finished) in
            print("seek finished \(finished)")
        })
    }
    
}

extension PlayerTestViewController: VIPlayerDelegate {
    
    func playerReadyToPlayer(_ player: VIPlayer) {
        if let playerItem = player.player.currentItem {
            totalTimeLabel.text = String(format: "%.1f", playerItem.duration.seconds)
        }
    }
    
    func player(_ player: VIPlayer, timeDidChange time: TimeInterval) {
        currentTimeLabel.text = String(format: "%.1f", time)
        if let playerItem = player.player.currentItem {
            timeSlider.value = Float(playerItem.currentTime().seconds / playerItem.duration.seconds)
        }
    }
    
    func player(_ player: VIPlayer, statusDidChange status: VIPlayer.PlayerStatus) {
        switch status {
        case .playing:
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            print("playing")
        case .pause(let reason):
            pauseButton.isEnabled = false
            playButton.isEnabled = true
            switch reason {
            case .manual:
                print("pause: manual pause")
            case .unstart:
                print("pause: not started")
            case .reachEnd:
                print("pause: player reach end")
            }
        case .loading(let reason):
            playButton.isEnabled = false
            pauseButton.isEnabled = true
            print("loading: \(reason)")
        }
    }
    
    func player(_ player: VIPlayer, didLoadedFailed error: Error?) {
        print("load media failed: \(String(describing: error?.localizedDescription))")
    }
    
    func player(_ player: VIPlayer, didLoadedTimeRanges timeRanges: [NSValue]) {
        var text = ""
        timeRanges.forEach { (value) in
            let timeRange = value.timeRangeValue
            text += String.init(format: "{%.1f, %.1f}", timeRange.start.seconds, timeRange.duration.seconds)
        }
        loadedTimeRangesLabel.text = text
        
        self.player(stateDidChanged: player)
    }
    
    func player(_ player: VIPlayer, isPlaybackBufferFull: Bool) {
        
    }
    
    func player(_ player: VIPlayer, isPlaybackBufferEmpty: Bool) {
        
    }
    
    func player(stateDidChanged player: VIPlayer) {
        avplayerRateLabel.text = "\(player.player.rate)"
        if let playerItem = player.player.currentItem {
            isPlaybackLikelyToKeepUpLabel.text = playerItem.isPlaybackLikelyToKeepUp ? "true": "false"
            playbackBufferFullLabel.text = playerItem.isPlaybackBufferFull ? "true" : "false"
            playbackBufferEmptyLabel.text = playerItem.isPlaybackBufferEmpty ? "true" : "false"
            
            if let timebase = playerItem.timebase {
                let rate = "\(CMTimebaseGetRate(timebase))"
                timebaseRateLabel.text = rate
            }
        }
        reasonForWaitingToPlayLabel.text = player.player.reasonForWaitingToPlay?.rawValue
        
        switch player.player.timeControlStatus {
        case .paused:
            timeControlStatusLabel.text = "pause"
        case .playing:
            timeControlStatusLabel.text = "playing"
        case .waitingToPlayAtSpecifiedRate:
            timeControlStatusLabel.text = "waitingToPlayAtSpecifiedRate"
        }
        
    }
}
