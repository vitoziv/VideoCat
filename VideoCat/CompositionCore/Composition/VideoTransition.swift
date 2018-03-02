//
//  VideoTransition.swift
//  VideoCat
//
//  Created by Vito on 01/03/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

protocol VideoTransition: class {
    var duration: CMTime { get }
    func renderPixelBuffer(destinationPixelBuffer: CVPixelBuffer,
                           foregroundPixelBuffer: CVPixelBuffer,
                           backgroundPixelBuffer: CVPixelBuffer,
                           forTweenFactor tween: Float64)
}

class NoneTransition: VideoTransition {
    
    var duration: CMTime
    
    init() {
        duration = kCMTimeZero
    }
    
    func renderPixelBuffer(destinationPixelBuffer: CVPixelBuffer, foregroundPixelBuffer: CVPixelBuffer, backgroundPixelBuffer: CVPixelBuffer, forTweenFactor tween: Float64) {
        let foregroundImage = CIImage(cvPixelBuffer: foregroundPixelBuffer)
        let backgroundImage = CIImage(cvPixelBuffer: backgroundPixelBuffer)
        let resultImage = foregroundImage.composited(over: backgroundImage)
        VideoCompositor.ciContext.render(resultImage, to: destinationPixelBuffer)
    }
}

class CrossDissolveTransition: NoneTransition {
    override func renderPixelBuffer(destinationPixelBuffer: CVPixelBuffer, foregroundPixelBuffer: CVPixelBuffer, backgroundPixelBuffer: CVPixelBuffer, forTweenFactor tween: Float64) {
        let foregroundImage = CIImage(cvPixelBuffer: foregroundPixelBuffer)
        let backgroundImage = CIImage(cvPixelBuffer: backgroundPixelBuffer)
        if let crossDissolveFilter = CIFilter(name: "CIDissolveTransition") {
            crossDissolveFilter.setValue(backgroundImage, forKey: "inputImage")
            crossDissolveFilter.setValue(foregroundImage, forKey: "inputTargetImage")
            crossDissolveFilter.setValue(tween, forKey: "inputTime")
            if let resultImage = crossDissolveFilter.outputImage {
                VideoCompositor.ciContext.render(resultImage, to: destinationPixelBuffer)
            }
        }
    }
}
