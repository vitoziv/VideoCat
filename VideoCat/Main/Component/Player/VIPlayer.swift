//
//  VIPlayer.swift
//  VideoCat
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

protocol VIPlayerDelegate: class {
    func playerReadyToPlayer(_ player: VIPlayer)
    
    func player(_ player: VIPlayer, timeDidChange time: TimeInterval)
    func player(_ player: VIPlayer, statusDidChange status: VIPlayer.PlayerStatus)
    func player(_ player: VIPlayer, didLoadedFailed error: Error?)
    
    func player(_ player: VIPlayer, didLoadedTimeRanges timeRanges: [NSValue])
    func player(_ player: VIPlayer, isPlaybackBufferFull: Bool)
    func player(_ player: VIPlayer, isPlaybackBufferEmpty: Bool)
}

extension VIPlayerDelegate {
    func playerReadyToPlayer(_ player: VIPlayer) {}
    
    func player(_ player: VIPlayer, timeDidChange time: TimeInterval) {}
    func player(_ player: VIPlayer, statusDidChange status: VIPlayer.PlayerStatus) {}
    func player(_ player: VIPlayer, didLoadedFailed error: NSError) {}
    
    func player(_ player: VIPlayer, didLoadedTimeRanges timeRanges: [NSValue]) {}
    func player(_ player: VIPlayer, isPlaybackBufferFull: Bool) {}
    func player(_ player: VIPlayer, isPlaybackBufferEmpty: Bool) {}
}

class VIPlayer: NSObject {
    
    enum PauseReason {
        case unstart
        case manual
        case reachEnd
    }
    
    enum PlayerStatus {
        case playing
        case loading(AVPlayer.WaitingReason)
        case pause(PauseReason)
    }
    
    @objc let player = AVPlayer()
    let playerView = VIPlayerView()
    weak var delegate: VIPlayerDelegate?
    private(set) var status: PlayerStatus = .pause(.unstart)
    
    private var currentPlayerItemChangedObserve: NSKeyValueObservation?
    
    private let observedKeyPaths = [
        #keyPath(AVPlayer.timeControlStatus),
        #keyPath(AVPlayer.currentItem.playbackLikelyToKeepUp),
        #keyPath(AVPlayer.currentItem.loadedTimeRanges),
        #keyPath(AVPlayer.currentItem.playbackBufferFull),
        #keyPath(AVPlayer.currentItem.playbackBufferEmpty),
        #keyPath(AVPlayer.currentItem.status)
    ]
    private static var observerContext = 0
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerObserve()
    }
    
    init(playerItem: AVPlayerItem? = nil) {
        super.init()
        addOPlayerObserve()
        playerView.player = player
        if let playerItem = playerItem {
            replaceCurrentItem(playerItem)
        }
    }
    
    convenience init(asset: AVAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        self.init(playerItem: playerItem)
    }
    
    convenience init(url: URL) {
        let asset = AVAsset(url: url)
        self.init(asset: asset)
    }
    
    func replaceCurrentItem(_ playerItem: AVPlayerItem) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        player.replaceCurrentItem(with: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
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
    
    // MARK: - KVO
    
    private var timeObserver: Any?
    
    private func addOPlayerObserve() {
        for keyPath in observedKeyPaths {
            player.addObserver(self, forKeyPath: keyPath, options: [.new, .initial], context: &VIPlayer.observerContext)
        }
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 20), queue: DispatchQueue.main) { [weak self] (time) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.player(strongSelf, timeDidChange: time.seconds)
        }
        
    }
    
    private func removePlayerObserve() {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
            for keyPath in observedKeyPaths {
                player.removeObserver(self, forKeyPath: keyPath, context: &VIPlayer.observerContext)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &VIPlayer.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if keyPath == #keyPath(AVPlayer.timeControlStatus) {
            switch player.timeControlStatus {
            case .playing:
                print("timeControlStatus playing")
                status = .playing
            case .paused:
                print("timeControlStatus paused")
                if case .pause(.reachEnd) = status {
                } else {
                    status = .pause(.manual)
                }
            case .waitingToPlayAtSpecifiedRate:
                print("timeControlStatus waitingToPlayAtSpecifiedRate")
                if let reason = player.reasonForWaitingToPlay {
                    status = .loading(reason)
                } else {
                    status = .loading(.noReason)
                }
            }
            delegate?.player(self, statusDidChange: status)
        } else if keyPath == #keyPath(AVPlayer.currentItem.playbackLikelyToKeepUp) {
            if let playerItem = player.currentItem {
                print("playerItem isPlaybackLikelyToKeepUp: \(playerItem.isPlaybackLikelyToKeepUp)")
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.loadedTimeRanges) {
            if let playerItem = player.currentItem {
                delegate?.player(self, didLoadedTimeRanges: playerItem.loadedTimeRanges)
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.playbackBufferFull) {
            if let playerItem = player.currentItem {
                delegate?.player(self, isPlaybackBufferFull: playerItem.isPlaybackBufferFull)
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.playbackBufferEmpty) {
            if let playerItem = player.currentItem {
                delegate?.player(self, isPlaybackBufferFull: playerItem.isPlaybackBufferEmpty)
            }
        } else if keyPath == #keyPath(AVPlayer.currentItem.status) {
            if let playerItem = player.currentItem {
                if playerItem.status == .readyToPlay {
                    delegate?.playerReadyToPlayer(self)
                } else if playerItem.status == .failed {
                    delegate?.player(self, didLoadedFailed: playerItem.error)
                }
            }
        }
    }
    
    // MARK: - Notification
    @objc private func playerDidFinishPlaying(notification: NSNotification) {
        status = .pause(.reachEnd)
    }
    
}

// MARK: - Helper

extension AVPlayer.WaitingReason {
    static let noReason = AVPlayer.WaitingReason(rawValue: "noReason")
}
