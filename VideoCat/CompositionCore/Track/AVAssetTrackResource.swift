//
//  AVAssetTrackResource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import UIKit

class AVAssetTrackResource: TrackResource {
    
    var assetURL: URL?
    var asset: AVAsset?
    
    init(assetURL: URL) {
        super.init()
        self.assetURL = assetURL
        asset = AVURLAsset(url: assetURL)
        if let asset = asset {
            let duration = CMTimeMake(Int64(asset.duration.seconds * 600), 600)
            selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration)
        }
    }
    
    required public init() {
        super.init()
    }
    
    // MARK: - Load
    override func prepare(completion: @escaping (ResourceStatus, Error?) -> Void) {
        if let asset = asset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                if asset.tracks.count > 0 {
                    strongSelf.status = .avaliable
                }
                completion(strongSelf.status, strongSelf.statusError)
            })
        } else {
            completion(status, statusError)
        }
    }
    
    // MARK: - Content provider
    
    open override func numberOfTracks(for mediaType: AVMediaType) -> Int {
        if let asset = asset {
            return asset.tracks(withMediaType: mediaType).count
        }
        return 0
    }
    
    open override func track(at index: Int, mediaType: AVMediaType) -> AVAssetTrack? {
        guard let asset = asset else {
            return nil
        }
        let tracks = asset.tracks(withMediaType: mediaType)
        return tracks[index]
    }
    
    // MARK: - NSCopying
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! AVAssetTrackResource
        resource.assetURL = assetURL
        resource.asset = asset
        
        return resource
    }
    
}
