//
//  TrackComposition.swift
//  VideoCat
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class TrackComposition {
    func createComposition(from trackPanel: TrackPanel) -> AVAsset {
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        var trackTime = kCMTimeZero
        trackPanel.trackItems.forEach { (trackItem) in
            composition.addMutableTrack(from: trackItem, at: trackTime)
            
            trackTime = trackTime + trackItem.configuration.realDuration()
        }
        
        return composition
    }
}
