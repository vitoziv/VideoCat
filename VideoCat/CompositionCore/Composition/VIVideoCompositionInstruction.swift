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
    
    func apply(request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
        if layerInstructions.count == 2 {
            let layerInstruction1 = layerInstructions[0]
            let layerInstruction2 = layerInstructions[1]
            if let sourcePixel1 = request.sourceFrame(byTrackID: layerInstruction1.trackID),
                let sourcePixel2 = request.sourceFrame(byTrackID: layerInstruction2.trackID) {
                
                let image1 = generateImage(from: sourcePixel1)
                let sourceImage1 = layerInstruction1.apply(sourceImage: image1, at: request.compositionTime, renderSize: request.renderContext.size)
                let image2 = generateImage(from: sourcePixel2)
                let sourceImage2 = layerInstruction2.apply(sourceImage: image2, at: request.compositionTime, renderSize: request.renderContext.size)
                
                let foregroundImage: CIImage = {
                    if foregroundTrackID == layerInstruction1.trackID {
                        return sourceImage1
                    } else {
                        return sourceImage2
                    }
                }()
                let backgroundImage: CIImage = {
                    if foregroundTrackID == layerInstruction1.trackID {
                        return sourceImage2
                    } else {
                        return sourceImage1
                    }
                }()
                
                let tweenFactor = factorForTimeInRange(request.compositionTime, range: timeRange)
                let transitionImage = transition?.renderImage(foregroundImage: foregroundImage, backgroundImage: backgroundImage, forTweenFactor: tweenFactor)
                assert(transition != nil)
                return transitionImage
            }
        } else {
            var image: CIImage?
            layerInstructions.forEach { (layerInstruction) in
                if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                    let sourceImage = layerInstruction.apply(sourceImage: CIImage(cvPixelBuffer: sourcePixel), at: request.compositionTime, renderSize: request.renderContext.size)
                    if let previousImage = image {
                        image = sourceImage.composited(over: previousImage)
                    } else {
                        image = sourceImage
                    }
                }
            }
            
            return image
        }
        
        return nil
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

class VIVideoCompositionLayerInstruction: AVMutableVideoCompositionLayerInstruction {
    
    var trackItem: TrackItem?
    
    func apply(sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage = sourceImage
        guard let trackItem = trackItem else {
            return finalImage
        }
        
        guard let track = trackItem.resource.trackAsset?.tracks(withMediaType: .video).first else {
            return finalImage
        }
        
        finalImage = finalImage.flipYCoordinate().transformed(by: track.preferredTransform).flipYCoordinate()
        
        var transform = CGAffineTransform.identity
        switch trackItem.configuration.baseContentMode {
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

