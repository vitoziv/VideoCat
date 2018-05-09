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

