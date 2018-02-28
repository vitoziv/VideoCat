//
//  TrackConfiguration.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

struct TrackConfiguration {
    
    enum BaseContentMode {
        case aspectFit
        case aspectFill
    }
    
    /// Resource's time range
    var timeRange: CMTimeRange = kCMTimeRangeZero
    
    var baseContentMode: BaseContentMode = .aspectFit
    
    
    /// Track's final duration, it will be calculated using track's time, speed and so on
    ///
    /// - Returns: time
    func finalDuration() -> CMTime {
        return timeRange.duration
    }
}
