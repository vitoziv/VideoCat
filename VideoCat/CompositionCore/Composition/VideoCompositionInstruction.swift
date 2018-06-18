//
//  VIVideoCompositionInstruction.swift
//  VideoCat
//
//  Created by Vito on 10/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class VideoCompositionInstruction: NSObject, AVVideoCompositionInstructionProtocol {
    
    var timeRange: CMTimeRange = CMTimeRange()
    var enablePostProcessing: Bool = false
    var containsTweening: Bool = false
    var requiredSourceTrackIDs: [NSValue]?
    var passthroughTrackID: CMPersistentTrackID = 0
    
    var layerInstructions: [VideoCompositionLayerInstruction] = []
    var mainTrackIDs: [Int32] = []
    
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
    
    func apply(request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
        let time = request.compositionTime
        let renderSize = request.renderContext.size
        
        var otherLayerInstructions: [VideoCompositionLayerInstruction] = []
        var mainLayerInstructions: [VideoCompositionLayerInstruction] = []
        
        let currentLayerInstructions = layerInstructions.filter({ $0.timeRange.containsTime(time) })
        for layerInstruction in currentLayerInstructions {
            if mainTrackIDs.contains(layerInstruction.trackID) {
                mainLayerInstructions.append(layerInstruction)
            } else {
                otherLayerInstructions.append(layerInstruction)
            }
        }
        
        var image: CIImage?
        
        if mainLayerInstructions.count == 2 {
            let layerInstruction1: VideoCompositionLayerInstruction
            let layerInstruction2: VideoCompositionLayerInstruction
            if mainLayerInstructions[0].timeRange.end < mainLayerInstructions[1].timeRange.end {
                layerInstruction1 = mainLayerInstructions[0]
                layerInstruction2 = mainLayerInstructions[1]
            } else {
                layerInstruction1 = mainLayerInstructions[1]
                layerInstruction2 = mainLayerInstructions[0]
            }
            
            if let sourcePixel1 = request.sourceFrame(byTrackID: layerInstruction1.trackID),
                let sourcePixel2 = request.sourceFrame(byTrackID: layerInstruction2.trackID) {
                
                let image1 = generateImage(from: sourcePixel1)
                let sourceImage1 = layerInstruction1.apply(sourceImage: image1, at: time, renderSize: renderSize)
                let image2 = generateImage(from: sourcePixel2)
                let sourceImage2 = layerInstruction2.apply(sourceImage: image2, at: time, renderSize: renderSize)
                
                let transitionTimeRange = layerInstruction1.timeRange.intersection(layerInstruction2.timeRange)
                let tweenFactor = factorForTimeInRange(time, range: transitionTimeRange)
                let transitionImage = layerInstruction1.trackItem.transition?.renderImage(foregroundImage: sourceImage1, backgroundImage: sourceImage2, forTweenFactor: tweenFactor)
                assert(layerInstruction1.trackItem.transition != nil)
                image = transitionImage
            }
        } else {
            mainLayerInstructions.forEach { (layerInstruction) in
                if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                    let sourceImage = layerInstruction.apply(sourceImage: CIImage(cvPixelBuffer: sourcePixel), at: time, renderSize: renderSize)
                    if let previousImage = image {
                        image = sourceImage.composited(over: previousImage)
                    } else {
                        image = sourceImage
                    }
                }
            }
        }
        
        otherLayerInstructions.forEach { (layerInstruction) in
            if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                let sourceImage = layerInstruction.apply(sourceImage: CIImage(cvPixelBuffer: sourcePixel), at: time, renderSize: renderSize)
                if let previousImage = image {
                    image = sourceImage.composited(over: previousImage)
                } else {
                    image = sourceImage
                }
            }
        }
        
        return image
    }
    
    /* 0.0 -> 1.0 */
    private func factorForTimeInRange( _ time: CMTime, range: CMTimeRange) -> Float64 {
        let elapsed = CMTimeSubtract(time, range.start)
        return CMTimeGetSeconds(elapsed) / CMTimeGetSeconds(range.duration)
    }
    
    private func generateImage(from pixelBuffer: CVPixelBuffer) -> CIImage {
        var image = CIImage(cvPixelBuffer: pixelBuffer)
        let attr = CVBufferGetAttachments(pixelBuffer, .shouldPropagate) as? [ String : Any ]
        if let attr = attr, !attr.isEmpty {
            if let aspectRatioDict = attr[kCVImageBufferPixelAspectRatioKey as String] as? [ String : Any ], !aspectRatioDict.isEmpty {
                let width = aspectRatioDict[kCVImageBufferPixelAspectRatioHorizontalSpacingKey as String] as? CGFloat
                let height = aspectRatioDict[kCVImageBufferPixelAspectRatioVerticalSpacingKey as String] as? CGFloat
                if let width = width, let height = height,  width != 0 && height != 0 {
                    image = image.transformed(by: CGAffineTransform.identity.scaledBy(x: width / height, y: 1))
                }
            }
        }
        return image
    }
}

class VideoCompositionLayerInstruction {
    
    var trackID: Int32
    var trackItem: TrackItem
    var timeRange: CMTimeRange = kCMTimeRangeZero
    
    init(trackID: Int32, trackItem: TrackItem) {
        self.trackID = trackID
        self.trackItem = trackItem
    }
    
    func apply(sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage = sourceImage
        
        guard let track = trackItem.resource.trackAsset?.tracks(withMediaType: .video).first else {
            return finalImage
        }
        
        finalImage = finalImage.flipYCoordinate().transformed(by: track.preferredTransform).flipYCoordinate()
        
        var transform = CGAffineTransform.identity
        switch trackItem.configuration.videoConfiguration.baseContentMode {
        case .aspectFit:
            let fitTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFitInRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fitTransform)
        case .aspectFill:
            let fillTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFillRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fillTransform)
        }
        finalImage = finalImage.transformed(by: transform)
        
        // TODO: other configuration
        
        let backgroundColor = CIColor(color: UIColor.black)
        let backgroundImage = CIImage(color: backgroundColor).cropped(to: CGRect(origin: .zero, size: renderSize))
        finalImage = finalImage.composited(over: backgroundImage)
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

