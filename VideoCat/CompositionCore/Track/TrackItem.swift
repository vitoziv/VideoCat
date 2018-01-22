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
    
    init(resource: TrackResource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
    }
    
}

extension AVMutableComposition {
    func addMutableTrack(from item: TrackItem, at time: CMTime) {
        if let asset = item.resource.trackAsset {
            asset.tracks.forEach({ (t) in
                guard t.mediaType == AVMediaType.video || t.mediaType == AVMediaType.audio else {
                    return
                }
                let track: AVMutableCompositionTrack? = {
                    if let track = tracks(withMediaType: t.mediaType).first {
                        return track
                    }
                    return addMutableTrack(withMediaType: t.mediaType, preferredTrackID: t.trackID)
                }()
                
                if let track = track {
                    do {
                        try track.insertTimeRange(item.configuration.timeRange, of: t, at: time)
                    } catch {
                        removeTrack(track)
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }
}

