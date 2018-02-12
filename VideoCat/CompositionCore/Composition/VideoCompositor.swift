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
    
    func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
        renderingQueue.async(execute: { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.shouldCancelAllRequests {
                request.finishCancelledRequest()
            } else {
                autoreleasepool(invoking: { () -> () in
                    do {
                        if let resultPixels = try strongSelf.newRenderedPixelBufferForRequest(request: request) {
                            request.finish(withComposedVideoFrame: resultPixels)
                        } else {
                            request.finishCancelledRequest()
                        }
                    } catch let e {
                        request.finish(with: e)
                    }
                })
            }
        })
    }
    
    func cancelAllPendingVideoCompositionRequests() {
        shouldCancelAllRequests = true
        renderingQueue.async(flags: .barrier) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shouldCancelAllRequests = false
        }
    }
    
    func newRenderedPixelBufferForRequest(request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer? {
        var image: CIImage?
        
        request.sourceTrackIDs.forEach { (trackID) in
            if let sourcePixel = request.sourceFrame(byTrackID: trackID.int32Value) {
                if let resultImage = image {
                    let sourceImage = CIImage(cvPixelBuffer: sourcePixel)
                    image = sourceImage.composited(over: resultImage)
                } else {
                    image = CIImage(cvPixelBuffer: sourcePixel)
                }
            }
        }
        
        return image?.pixelBuffer
    }
    
}
