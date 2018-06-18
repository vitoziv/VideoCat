//
//  Timeline.swift
//  VideoCat
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class Timeline {
    var renderSize = CGSize.zero
    var trackItems: [TrackItem] = []
}

// MARK: - Reload
extension Timeline {
    
    func performUpdate(_ updateBlock: () -> Void) {
        updateBlock()
        reloadTimeline()
    }
    
    func reloadTimeline() {
        reloadTimelineDuration()
        reloadTimelineStartTime()
    }
    
    private func reloadTimelineDuration() {
        trackItems.forEach({ $0.reloadTimelineDuration() })
    }
    
    private func reloadTimelineStartTime() {
        var trackTime = kCMTimeZero
        var previousTransitionDuration = kCMTimeZero
        for index in 0..<trackItems.count {
            let trackItem = trackItems[index]
            
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration: CMTime = {
                if let duration = trackItem.transition?.duration {
                    return duration
                }
                return kCMTimeZero
            }()
            let trackDuration = trackItem.configuration.timelineTimeRange.duration
            if trackDuration < transitionDuration {
                transitionDuration = kCMTimeZero
            } else {
                if index < trackItems.count - 1 {
                    let nextTrackItem = trackItems[index + 1]
                    if nextTrackItem.configuration.timelineTimeRange.duration < transitionDuration {
                        transitionDuration = kCMTimeZero
                    }
                } else {
                    transitionDuration = kCMTimeZero
                }
            }
            
            trackTime = trackTime - previousTransitionDuration
            
            trackItem.configuration.timelineTimeRange.start = trackTime
            
            previousTransitionDuration = transitionDuration
            trackTime = trackTime + trackDuration
        }
    }
    
}

