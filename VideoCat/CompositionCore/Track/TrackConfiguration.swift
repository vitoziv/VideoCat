//
//  TrackConfiguration.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

struct TrackConfiguration {
    var timeRange: CMTimeRange = kCMTimeRangeZero
    
    
    /// Track's final duration, it will be calculated using track's time, speed and so on
    ///
    /// - Returns: time
    func realDuration() -> CMTime {
        return timeRange.duration
    }
}
