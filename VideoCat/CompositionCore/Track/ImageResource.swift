//
//  ImageResource.swift
//  VideoCat
//
//  Created by Vito on 2018/7/27.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import CoreImage


/// Provider a Image as video frame
open class ImageResource: Resource {
    
    init(image: CIImage) {
        super.init()
        self.image = image
        self.status = .avaliable
    }
    
    required public init() {
        super.init()
    }
    
    public var image: CIImage? = nil
    
    open func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        return image
    }
    
    open override func tracks(for type: AVMediaType) -> [AVAssetTrack] {
        if type != .video {
            return []
        }
        return ImageResource.emptyAsset.tracks(withMediaType: type)
    }
    
    // MARK: - NSCopying
    open override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! ImageResource
        resource.image = image
        return resource
    }
    
    // MARK: - Helper
    
    private static let emptyAsset: AVAsset = {
        let url = Bundle.main.url(forResource: "black_empty", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        return asset
    }()
}
