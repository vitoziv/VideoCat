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
                if let track = addMutableTrack(withMediaType: t.mediaType, preferredTrackID: t.trackID) {
                    do {
                        try track.insertTimeRange(item.configuration.timeRange, of: track, at: time)
                    } catch {
                        removeTrack(track)
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }
}

