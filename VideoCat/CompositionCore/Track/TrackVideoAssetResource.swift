//
//  TrackVideoAssetResource.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Photos

class TrackVideoAssetResource: TrackResource {
    
    var identifier: String
    var asset: PHAsset?
    
    init(asset: PHAsset) {
        identifier = asset.localIdentifier
        super.init(with: nil)
        self.asset = asset
    }
    
    // MARK: - Load
    override func loadMedia(completion: @escaping (TrackResource.Status) -> Void) {
        if let asset = trackAsset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                defer {
                    completion(strongSelf.status)
                }
                
                var error: NSError?
                let tracksStatus = asset.statusOfValue(forKey: "tracks", error: &error)
                if tracksStatus != .loaded {
                    print("Failed to load tracks, status: \(tracksStatus), error: \(String(describing: error))")
                    return
                }
                let durationStatus = asset.statusOfValue(forKey: "duration", error: &error)
                if durationStatus != .loaded {
                    print("Failed to duration tracks, status: \(tracksStatus), error: \(String(describing: error))")
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
            completion(status)
            return
        }
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] (asset, audioMix, info) in
            guard let strongSelf = self else { return }
            if let asset = asset {
                strongSelf.trackAsset = asset
                strongSelf.status = .avaliable
            } else {
                strongSelf.status = .unavaliable
            }
            DispatchQueue.main.async {            
                completion(strongSelf.status)
            }
        }
    }
    
    // MARK: - Encoder
    override func encodeToJSON() -> [String: Any] {
        var json = super.encodeToJSON()
        json[TrackVideoAssetResource.IdentifierKey] = identifier
        return json
    }
    
    static let IdentifierKey = "IdentifierKey"
    required init(with json: [String : Any]?) {
        identifier = ""
        super.init(with: json)
        
        guard let json = json else {
            return
        }
        
        if let id = json[TrackVideoAssetResource.IdentifierKey] as? String {
            identifier = id
        }
    }
    
}
