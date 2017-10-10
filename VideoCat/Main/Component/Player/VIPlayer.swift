//
//  VIPlayer.swift
//  VideoCat
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

enum VIPlayerStatus: Int {
    case unknown
    case loading
    case playing
    case pause
}

class VIPlayer {
    
    var player: AVPlayer
    
    init(playerItem: AVPlayerItem) {
        player = AVPlayer(playerItem: playerItem)
    }
    
    convenience init(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        self.init(playerItem: playerItem)
    }
    
    convenience init(url: URL) {
        let asset = AVAsset(url: url)
        self.init(asset: asset)
    }
    
    // MARK: - Actions
    
    func play() {
        player.play()
    }
    
    func seek(to percent: Double, completion: @escaping (Bool) -> Void) {
        guard let duration = player.currentItem?.duration else {
            completion(false)
            return
        }
        let seconds = duration.seconds * percent
        let time = CMTimeMakeWithSeconds(seconds, duration.timescale)
        player.seek(to: time, completionHandler: completion)
    }
    
    func pause() {
        player.pause()
    }
    
    func reset() {
        player.pause()
        player.seek(to: kCMTimeZero)
    }
    
}
