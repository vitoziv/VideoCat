//
//  Resource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage


public enum ResourceStatus: Int {
    case unavaliable
    case avaliable
}

open class Resource: NSObject, NSCopying {

    required override public init() {
    }
    
    /// Max duration of this resource
    open var duration: CMTime = kCMTimeZero
    
    /// Selected time range, indicate how many resources will be inserted to AVCompositionTrack
    open var selectedTimeRange: CMTimeRange = kCMTimeRangeZero
    
    /// Natural frame size of this resource
    open var size: CGSize = .zero
    
    // MARK: - NSCopying
    open func copy(with zone: NSZone? = nil) -> Any {
        let resource = type(of: self).init()
        resource.duration = duration
        resource.selectedTimeRange = selectedTimeRange
        return resource
    }
    
}

open class ImageResource: Resource {
    
    public var image: CIImage? = nil
    
    open func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }
    
    // MARK: - NSCopying
    open override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! ImageResource
        resource.image = image
        return resource
    }
}

open class TrackResource: Resource {
    
    // MARK: - Load Media before use resource
    
    public var status: ResourceStatus = .unavaliable
    public var statusError: Error?
    
    open func prepare(completion: @escaping (ResourceStatus, Error?) -> Void) {
        status = .unavaliable
        statusError = NSError.init(domain: "com.resource.status", code: 0, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Empty resource", comment: "")])
        completion(status, statusError)
    }
    
    // MARK: - Content provider
    
    open func numberOfTracks(for mediaType: AVMediaType) -> Int {
        fatalError("Should implemented by subclass")
    }
    open func track(at index: Int, mediaType: AVMediaType) -> AVAssetTrack? {
        fatalError("Should implemented by subclass")
    }
    
    // MARK: - NSCopying
    open override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! TrackResource
        resource.status = status
        resource.statusError = statusError
        return resource
    }
}
