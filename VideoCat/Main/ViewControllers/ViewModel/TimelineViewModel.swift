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
    
    init() {
        let width = UIScreen.main.bounds.width * UIScreen.main.scale
        let height: CGFloat = round(width * 0.5625)
        timeline.renderSize = CGSize(width: width, height: height)
    }
    
    private lazy var compositionGenerator: CompositionGenerator = {
        return CompositionGenerator(timeline: self.timeline)
    }()
    
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
        let playerItem = compositionGenerator.buildPlayerItem()
        self.playerItem = playerItem
    }
    
}
