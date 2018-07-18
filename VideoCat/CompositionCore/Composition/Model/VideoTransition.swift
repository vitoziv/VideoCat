//
//  VideoTransition.swift
//  VideoCat
//
//  Created by Vito on 01/03/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import CoreMedia

public protocol VideoTransition: class {
    var identifier: String { get }
    var duration: CMTime { get }
    func renderImage(foregroundImage: CIImage,
                     backgroundImage: CIImage,
                     forTweenFactor tween: Float64) -> CIImage
}

open class NoneTransition: VideoTransition {
    public var identifier: String {
        return String(describing: self)
    }
    
    open var duration: CMTime
    
    public init(duration: CMTime = kCMTimeZero) {
        self.duration = duration
    }
    
    open func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64) -> CIImage {
        return foregroundImage.composited(over: backgroundImage)
    }
}

public class CrossDissolveTransition: NoneTransition {
    
    override public func renderImage(foregroundImage: CIImage, backgroundImage: CIImage, forTweenFactor tween: Float64) -> CIImage {
        if let crossDissolveFilter = CIFilter(name: "CIDissolveTransition") {
            crossDissolveFilter.setValue(foregroundImage, forKey: "inputImage")
            crossDissolveFilter.setValue(backgroundImage, forKey: "inputTargetImage")
            crossDissolveFilter.setValue(tween, forKey: "inputTime")
            if let outputImage = crossDissolveFilter.outputImage {
                return outputImage
            }
        }
        return super.renderImage(foregroundImage: foregroundImage, backgroundImage: backgroundImage, forTweenFactor: tween)
    }
}
