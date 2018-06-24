//
//  TrackConfiguration.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class TrackConfiguration {
    
    // MARK: - Timing
    
    /// Track's final time range, it will be calculated using track's time, speed, transition and so on
    var timelineTimeRange: CMTimeRange = kCMTimeRangeZero
    
    // MARK: - Media
    var videoConfiguration: VideoConfiguration = .createDefaultConfiguration()
    var audioConfiguration: AudioConfiguration = .createDefaultConfiguration()
}

public class VideoConfiguration {
    
    static func createDefaultConfiguration() -> VideoConfiguration {
        return VideoConfiguration()
    }
    
    enum BaseContentMode {
        case aspectFit
        case aspectFill
    }
    var baseContentMode: BaseContentMode = .aspectFit
}

public class AudioConfiguration {
    
    static func createDefaultConfiguration() -> AudioConfiguration {
        return AudioConfiguration()
    }

    var volume: Float = 1.0;
    var audioTapHolder: AudioProcessingTapHolder?
}
