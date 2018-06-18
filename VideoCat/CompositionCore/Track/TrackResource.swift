//
//  TrackResource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage
import UIKit

class ImageAsset {
    var image: CIImage
    var duration: CMTime
    init(image: CIImage, duration: CMTime) {
        self.image = image
        self.duration = duration
    }
}

class TrackResource {
    
    // MARK: - Resource Media
    
    /// supported type: audio and video
    open var trackAsset: AVAsset?
    /// Resource's time range
    var timeRange = kCMTimeRangeZero
    
    // MARK: - Load Media before use resource
    
    enum Status {
        case unavaliable
        case avaliable
    }
    var status: Status = .unavaliable
    open func loadMedia(completion: @escaping (Status) -> Void) {
        completion(status)
    }
    
    // MARK: - Thumb
    
    private var cachedThumbImage: UIImage?
    func requestThumbImage(maximumSize: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        guard cachedThumbImage == nil else {
            return cachedThumbImage
        }
        if let asset = trackAsset {
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = maximumSize
            if let image = try? imageGenerator.copyCGImage(at: kCMTimeZero, actualTime: nil) {
                cachedThumbImage = UIImage(cgImage: image)
            }
        }
        return cachedThumbImage
    }
    
    // MARK: - Encoder
    
    func encodeToJSON() -> [String: Any] {
        var json = [String: Any]()
        json[TrackResource.ResourceClassNameKey] = NSStringFromClass(type(of: self))
        return json
    }
    
    required init(with json: [String: Any]?) {
        
    }
    
    static let ResourceClassNameKey = "ResourceClassNameKey"
    static func createResource(from json: [String: Any]) -> TrackResource? {
        if let className = json[ResourceClassNameKey] as? String, let resourceClass = NSClassFromString(className) as? TrackResource.Type {
            return resourceClass.init(with: json)
        }
        return nil
    }
    
}
