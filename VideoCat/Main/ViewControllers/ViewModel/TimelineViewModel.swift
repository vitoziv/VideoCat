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
    
    func addTrackItem(_ trackItem: TrackItem) {
        timeline.trackItems.append(trackItem)
    }
    
    func insertTrackItem(_ tackItem: TrackItem, at index: Int) {
        timeline.trackItems.insert(tackItem, at: index)
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
    
}
