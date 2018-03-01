//
//  VIVideoCompositionInstruction.swift
//  VideoCat
//
//  Created by Vito on 10/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class VIVideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    /// ID used by subclasses to identify the foreground frame.
    var foregroundTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    /// ID used by subclasses to identify the background frame.
    var backgroundTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var timeRange: CMTimeRange = CMTimeRange()
    
    var enablePostProcessing: Bool = false
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID = 0
    
    var layerInstructions: [VIVideoCompositionLayerInstruction] = []
    
    init(thePassthroughTrackID: CMPersistentTrackID, forTimeRange theTimeRange: CMTimeRange) {
        super.init()
        
        passthroughTrackID = thePassthroughTrackID
        timeRange = theTimeRange
        
        requiredSourceTrackIDs = [NSValue]()
        containsTweening = false
        enablePostProcessing = false
    }
    
    init(theSourceTrackIDs: [NSValue], forTimeRange theTimeRange: CMTimeRange) {
        super.init()
        
        requiredSourceTrackIDs = theSourceTrackIDs
        timeRange = theTimeRange
        
        passthroughTrackID = kCMPersistentTrackID_Invalid
        containsTweening = true
        enablePostProcessing = false
    }
    
}

class VIVideoCompositionLayerInstruction: AVMutableVideoCompositionLayerInstruction {
    
    var trackItem: TrackItem?
    
    func apply(sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        guard let trackItem = trackItem else {
            return sourceImage
        }
        
        guard let track = trackItem.resource.trackAsset?.tracks(withMediaType: .video).first else {
            return sourceImage
        }
        
        var finalImage = sourceImage.flipYCoordinate().transformed(by: track.preferredTransform).flipYCoordinate()
        let sourceSize = finalImage.extent.size
        
        var transform = CGAffineTransform.identity
        switch trackItem.configuration.baseContentMode {
        case .aspectFit:
            let fitTransform = CGAffineTransform.transform(by: sourceSize, aspectFitInSize: renderSize)
            transform = transform.concatenating(fitTransform)
        case .aspectFill:
            let fillTransform = CGAffineTransform.transform(by: sourceSize, aspectFillSize: renderSize)
            transform = transform.concatenating(fillTransform)
        }
        finalImage = finalImage.transformed(by: transform)
        
        // TODO: other configuration
        
        return finalImage
    }
    
}

private extension CIImage {
    func flipYCoordinate() -> CIImage {
        // Invert Y coordinate
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
}

