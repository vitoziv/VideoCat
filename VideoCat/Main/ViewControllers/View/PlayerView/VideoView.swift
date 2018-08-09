//
//  VideoView.swift
//  VideoCat
//
//  Created by Vito on 06/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import VIPlayer

class VideoView: UIView {
    
    var player = VIPlayer()
    
    var controlView: VideoControlView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        player.delegate = self
        
        let playerView = player.playerView
        addSubview(playerView)
        
        controlView = VideoControlView()
        addSubview(controlView)
        controlView.playPauseButton.addTarget(self, action: #selector(playPauseAction(sender:)), for: .touchUpInside)
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        playerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        playerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        playerView.bottomAnchor.constraint(equalTo: controlView.topAnchor).isActive = true
        playerView.widthAnchor.constraint(equalTo: playerView.heightAnchor, multiplier: 16/9).isActive = true
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        controlView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        controlView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        controlView.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func configure(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(playerItem)
    }
    
    func configure(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(playerItem)
    }
    
    @objc private func playPauseAction(sender: UIButton) {
        switch player.status {
        case .pause(_):
            player.play()
        default:
            player.pause()
        }
    }

}

extension VideoView: VIPlayerDelegate {
    
    func player(_ player: VIPlayer, didLoadedFailed error: Error?) {
        controlView.update(to: .pause)
    }
    
    func player(_ player: VIPlayer, timeDidChange time: TimeInterval) {
        controlView.currentTimeLabel.text = String(format: "%0.1f", time)
    }
    
    func player(_ player: VIPlayer, statusDidChange status: VIPlayer.PlayerStatus) {
        switch status {
        case .pause(_):
            controlView.update(to: .pause)
        default:
            controlView.update(to: .play)
        }
    }
    
}


class VideoControlView: UIView {
    
    var currentTimeLabel: UILabel!
    var playPauseButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "0"
        currentTimeLabel.textColor = UIColor.contentColor
        currentTimeLabel.font = UIFont.detailFont
        addSubview(currentTimeLabel)
        
        playPauseButton = UIButton(type: .system)
        addSubview(playPauseButton)
        playPauseButton.setTitle("play", for: .normal)
        
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        let leftConstraint = currentTimeLabel.leftAnchor.constraint(equalTo: leftAnchor)
        leftConstraint.constant = 15
        leftConstraint.isActive = true
        currentTimeLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        currentTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        playPauseButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        playPauseButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    enum ControlState {
        case pause
        case play
    }
    
    var state: ControlState = .pause
    
    func update(to state: ControlState) {
        switch state {
        case .pause:
            playPauseButton.setTitle("play", for: .normal)
        case .play:
            playPauseButton.setTitle("pause", for: .normal)
        }
    }
    
}
