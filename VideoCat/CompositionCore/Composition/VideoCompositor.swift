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
    
    static let ciContext: CIContext = CIContext()
    private let renderContextQueue: DispatchQueue = DispatchQueue(label: "videocore.rendercontextqueue")
    private let renderingQueue: DispatchQueue = DispatchQueue(label: "videocore.renderingqueue")
    private var renderContextDidChange = false
    private var shouldCancelAllRequests = false
    private var renderContext: AVVideoCompositionRenderContext?
    
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
        var image = CIImage(cvPixelBuffer: outputPixels)
        
        // Background
        let backgroundColor = CIColor(color: UIColor.black)
        let backgroundImage = CIImage(color: backgroundColor).cropped(to: image.extent)
        image = backgroundImage.composited(over: image)
        
        if let destinationPixelBuffer = renderContext?.newPixelBuffer() {
            instruction.apply(destinationPixelBuffer: destinationPixelBuffer, request: request)
            let destinationImage = CIImage(cvPixelBuffer: destinationPixelBuffer)
            image = destinationImage.composited(over: image)
            
        }
        
        VideoCompositor.ciContext.render(image, to: outputPixels)
        
        return outputPixels
    }
    
}
