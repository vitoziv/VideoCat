//
//  VideoCompositor.swift
//  VideoCat
//
//  Created by Vito on 06/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

class VideoCompositor: NSObject, AVFoundation.AVVideoCompositing  {
    
    fileprivate static let ciContext: CIContext = CIContext()
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "videocore.rendercontextqueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "videocore.renderingqueue")
    private var renderContextDidChange = false
    private var shouldCancelAllRequests = false
    private var renderContext: AVVideoCompositionRenderContext?
    
    fileprivate lazy var colorGeneratorFilter: CIFilter = {
        return CIFilter(name: "CIConstantColorGenerator")!
    }()
    
    var sourcePixelBufferAttributes: [String : Any]? =
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] =
        [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
         String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync(execute: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.renderContext = newRenderContext
            strongSelf.renderContextDidChange = true
        })
    }
    
    enum PixelBufferRequestError: Error {
        case newRenderedPixelBufferForRequestFailure
    }
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        autoreleasepool {
            renderingQueue.async(execute: { [weak self] in
                guard let strongSelf = self else { return }
                if strongSelf.shouldCancelAllRequests {
                    request.finishCancelledRequest()
                } else {
                    if let resultPixels = strongSelf.newRenderedPixelBufferForRequest(request: request) {
                        request.finish(withComposedVideoFrame: resultPixels)
                    } else {
                        request.finish(with: PixelBufferRequestError.newRenderedPixelBufferForRequestFailure)
                    }
                }
            })
        }
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllRequests = true
        renderingQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shouldCancelAllRequests = false
        }
    }
    
    func newRenderedPixelBufferForRequest(request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
        guard let outputPixels = renderContext?.newPixelBuffer() else { return nil }
        guard let instruction = request.videoCompositionInstruction as? VIVideoCompositionInstruction else {
            return nil
        }
        
        var image = generateBackgroundImage(pixelBuffer: outputPixels)
        instruction.layerInstructions.forEach { (layerInstruction) in
            if let sourcePixel = request.sourceFrame(byTrackID: layerInstruction.trackID) {
                var sourceImage = CIImage(cvPixelBuffer: sourcePixel)
                sourceImage = layerInstruction.apply(sourceImage: sourceImage, at: request.compositionTime, renderSize: request.renderContext.size)
                
                image = sourceImage.composited(over: image)
            }
        }
        
        VideoCompositor.ciContext.render(image, to: outputPixels)
        
        return outputPixels
    }
    
    fileprivate func generateBackgroundImage(pixelBuffer: CVPixelBuffer) -> CIImage {
        let color = CIColor(color: UIColor.black)
        colorGeneratorFilter.setValue(color, forKey: "inputColor")
        if let outputImage = colorGeneratorFilter.outputImage {
            VideoCompositor.ciContext.render(outputImage, to: pixelBuffer)
        }
        return CIImage(cvPixelBuffer: pixelBuffer)
    }
    
}
