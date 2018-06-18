//
//  TrackItem.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class TrackItem {
    
    var identifier: String
    var resource: TrackResource
    var configuration: TrackConfiguration
    var transition: VideoTransition?
    
    init(resource: TrackResource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
    }
    
}

extension TrackItem {
    func reloadTimelineDuration() {
        let duration = resource.timeRange.duration
        var timeRange = configuration.timelineTimeRange
        timeRange.duration = duration
        configuration.timelineTimeRange = timeRange
    }
}
