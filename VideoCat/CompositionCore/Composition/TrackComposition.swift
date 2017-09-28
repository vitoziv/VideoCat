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
        
        trackPanel.trackItems.forEach { (trackItem) in
            if let time = trackPanel.trackItemsTimeInfo[trackItem.identifier] {
                composition.addMutableTrack(from: trackItem, at: time)
            }
        }
        
        return composition
    }
}
