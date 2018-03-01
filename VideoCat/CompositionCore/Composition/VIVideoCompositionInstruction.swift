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
    
    /// Video transition
    var transition: VideoTransition?
    
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
    
    func apply(destinationPixelBuffer: CVPixelBuffer, request: AVAsynchronousVideoCompositionRequest) {
        if layerInstructions.count == 2 {
            let layerInstruction1 = layerInstructions[0]
            let layerInstruction2 = layerInstructions[1]
            
            if let sourcePixel1 = request.sourceFrame(byTrackID: layerInstruction1.trackID),
                let sourcePixel2 = request.sourceFrame(byTrackID: layerInstruction2.trackID),
                let sourceDestinationPixelBuffer1 = request.renderContext.newPixelBuffer(),
                let sourceDestinationPixelBuffer2 = request.renderContext.newPixelBuffer() {
                
                layerInstruction1.apply(destinationPixelBuffer: sourceDestinationPixelBuffer1,
                                        sourcePixelBuffer: sourcePixel1,
                                        at: request.compositionTime,
                                        renderSize: request.renderContext.size)
                
                layerInstruction2.apply(destinationPixelBuffer: sourceDestinationPixelBuffer2,
                                        sourcePixelBuffer: sourcePixel2,
                                        at: request.compositionTime,
                                        renderSize: request.renderContext.size)
                
                let foregroundDestinationPixelBuffer: CVPixelBuffer = {
                    if foregroundTrackID == layerInstruction1.trackID {
                        return sourceDestinationPixelBuffer1
                    } else {
                        return sourceDestinationPixelBuffer2
                    }
                }()
                let backgroundDestinationPixelBuffer: CVPixelBuffer = {
                    if foregroundTrackID == layerInstruction1.trackID {
                        return sourceDestinationPixelBuffer2
                    } else {
                        return sourceDestinationPixelBuffer1
                    }
                }()
                // TODO: 合成两个画面到 destinationPixelBuffer
                let tweenFactor = factorForTimeInRange(request.compositionTime, range: timeRange)
                transition?.renderPixelBuffer(destinationPixelBuffer: destinationPixelBuffer,
                                              foregroundPixelBuffer: foregroundDestinationPixelBuffer,
                                              backgroundPixelBuffer: backgroundDestinationPixelBuffer,
                                              forTweenFactor: tweenFactor)
            }
        } else {
            var image: CIImage?
            layerInstructions.forEach { (layerInstruction) in
                if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                    layerInstruction.apply(destinationPixelBuffer: destinationPixelBuffer,
                                           sourcePixelBuffer: sourcePixel,
                                           at: request.compositionTime,
                                           renderSize: request.renderContext.size)
                    if let previousImage = image {
                        let sourceImage = CIImage(cvPixelBuffer: destinationPixelBuffer)
                        image = sourceImage.composited(over: previousImage)
                    } else {
                        image = CIImage(cvPixelBuffer: destinationPixelBuffer)
                    }
                }
            }
            if layerInstructions.count > 1, let image = image {
                VideoCompositor.ciContext.render(image, to: destinationPixelBuffer)
            }
        }
    }
    
    /* 0.0 -> 1.0 */
    private func factorForTimeInRange( _ time: CMTime, range: CMTimeRange) -> Float64 {
        let elapsed = CMTimeSubtract(time, range.start)
        return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration)
    }
}

class VIVideoCompositionLayerInstruction: AVMutableVideoCompositionLayerInstruction {
    
    var trackItem: TrackItem?
    
    func apply(destinationPixelBuffer: CVPixelBuffer, sourcePixelBuffer: CVPixelBuffer, at time: CMTime, renderSize: CGSize) {
        var finalImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
        guard let trackItem = trackItem else {
            VideoCompositor.ciContext.render(finalImage, to: destinationPixelBuffer)
            return
        }
        
        guard let track = trackItem.resource.trackAsset?.tracks(withMediaType: .video).first else {
            VideoCompositor.ciContext.render(finalImage, to: destinationPixelBuffer)
            return
        }
        
        finalImage = finalImage.flipYCoordinate().transformed(by: track.preferredTransform).flipYCoordinate()
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
        
        let backgroundColor = CIColor(color: UIColor.black)
        let backgroundImage = CIImage(color: backgroundColor)
        finalImage = finalImage.composited(over: backgroundImage)
        VideoCompositor.ciContext.render(finalImage, to: destinationPixelBuffer)
    }
    
}

private extension CIImage {
    func flipYCoordinate() -> CIImage {
        // Invert Y coordinate
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
}

