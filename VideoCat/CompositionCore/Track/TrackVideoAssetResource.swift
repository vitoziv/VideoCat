//
//  TrackVideoAssetResource.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Photos

class TrackVideoAssetResource: TrackResource {
    
    var identifier: String = ""
    var asset: PHAsset?
    fileprivate var avasset: AVAsset?
    
    init(asset: PHAsset) {
        super.init()
        identifier = asset.localIdentifier
        self.asset = asset
        let duration = CMTimeMake(Int64(asset.duration * 600), 600)
        selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration)
    }
    
    required public init() {
        super.init()
    }
    
    // MARK: - Load
    override func prepare(completion: @escaping (ResourceStatus, Error?) -> Void) {
        if let asset = self.avasset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                defer {
                    completion(strongSelf.status, strongSelf.statusError)
                }
                
                var error: NSError?
                let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
                if tracksStatus != .loaded {
                    Log.error("Failed to load tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
                let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
                if durationStatus != .loaded {
                    Log.error("Failed to duration tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
                strongSelf.status = .avaliable
            })
            return
        }
        
        if asset == nil {
            asset = PHAsset.fetchAssets(withBurstIdentifier: identifier, options: nil).lastObject
        }
        
        guard let asset = asset else {
            completion(status, nil)
            return
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] (asset, audioMix, info) in
            guard let strongSelf = self else { return }
            if let asset = asset {
                strongSelf.avasset = asset
                strongSelf.status = .avaliable
            } else {
                strongSelf.status = .unavaliable
            }
            DispatchQueue.main.async {
                completion(strongSelf.status, nil)
            }
        }
    }
    
    // MARK: - NSCopying
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let resource = super.copy(with: zone) as! TrackVideoAssetResource
        resource.asset = asset
        resource.avasset = avasset
        resource.identifier = identifier
        
        return resource
    }
}
