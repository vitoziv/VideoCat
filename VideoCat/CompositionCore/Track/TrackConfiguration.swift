//
//  TrackConfiguration.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class TrackConfiguration {
    
    // MARK: - Timing
    
    /// Track's final time range, it will be calculated using track's time, speed, transition and so on
    var timelineTimeRange: CMTimeRange = kCMTimeRangeZero
    
    // MARK: - Media
    var videoConfiguration: VideoConfiguration = .default
    var audioConfiguration: AudioConfiguration = .default
}

class VideoConfiguration {
    
    static let `default` = VideoConfiguration()
    
    enum BaseContentMode {
        case aspectFit
        case aspectFill
    }
    var baseContentMode: BaseContentMode = .aspectFit
}

class AudioConfiguration {
    static let `default` = AudioConfiguration()
    var volume: Float = 1.0;
    var audioTapHolder: AudioProcessingTapHolder?
}
