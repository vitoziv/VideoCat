//
//  Resource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

open class Resource: NSObject, NSCopying {

    required override public init() {
    }
    
    /// MARK: - Resource's time range
    open var duration: CMTime = kCMTimeZero
    open var selectedTimeRange: CMTimeRange = kCMTimeRangeZero
    
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
    
    func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
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
    
    public enum ResourceStatus: Int {
        case unavaliable
        case avaliable
    }

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
        return 0
    }
    open func track(at index: Int, mediaType: AVMediaType) -> AVAssetTrack? {
        return nil
    }
    
    // MARK: - NSCopying
    open override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! TrackResource
        resource.status = status
        resource.statusError = statusError
        return resource
    }
}
