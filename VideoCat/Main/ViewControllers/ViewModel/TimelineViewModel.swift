//
//  PanelViewModel.swift
//  VideoCat
//
//  Created by Vito on 28/10/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation
import AVFoundation

class TimelineViewModel {
    let timeline = Timeline()
    
    private(set) var playerItem = AVPlayerItem(asset: AVComposition.init())
    
    func addTrackItem(_ trackItem: TrackItem) {
        timeline.trackItems.append(trackItem)
        reloadPlayerItem()
    }
    
    func insertTrackItem(_ tackItem: TrackItem, at index: Int) {
        timeline.trackItems.insert(tackItem, at: index)
        reloadPlayerItem()
    }
    
    func timeRange(at index: Int) -> CMTimeRange {
        var startTime = kCMTimeZero
        for i in (0..<index) {
            let trackItem = timeline.trackItems[i]
            startTime = CMTimeAdd(startTime, trackItem.configuration.timeRange.duration)
        }
        if index >= timeline.trackItems.count {
            return CMTimeRangeMake(startTime, kCMTimeZero)
        }
        let trackItem = timeline.trackItems[index]
        return trackItem.configuration.timeRange
    }
    
    fileprivate func reloadPlayerItem() {
        let composition = timeline.buildComposition()
        let playerItem = AVPlayerItem(asset: composition)
//        playerItem.videoComposition = timeline.buildVideoComposition()
//        playerItem.audioMix = timeline.buildAudioMix()
        self.playerItem = playerItem
    }
    
}
