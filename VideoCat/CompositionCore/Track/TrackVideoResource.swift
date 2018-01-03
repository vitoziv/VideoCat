//
//  TrackVideoResource.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class TrackVideoResource: TrackResource {
    
    var assetURL: URL
    var timeRange = kCMTimeRangeZero
    
    init(asset: AVURLAsset) {
        assetURL = asset.url
        super.init(with: nil)
        trackAsset = asset
        let duration = CMTimeMake(Int64(asset.duration * 600), 600)
        timeRange = CMTimeRangeMake(kCMTimeZero, duration)
    }
    
    // MARK: - Load
    
    override func loadMedia(completion: @escaping (Status) -> Void) {
        if trackAsset == nil {
            trackAsset = AVAsset(url: assetURL)
        }
        if let asset = trackAsset {
            asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"], completionHandler: { [weak self] in
                guard let strongSelf = self else { return }
                if asset.tracks.count > 0 {
                    strongSelf.status = .avaliable
                }
                completion(strongSelf.status)
            })
        } else {
            completion(status)
        }
    }
    
    // MARK: - Encoder
    override func encodeToJSON() -> [String: Any] {
        var json = super.encodeToJSON()
        json[TrackVideoResource.AssetURLKey] = assetURL.absoluteString.replacingOccurrences(of: NSHomeDirectory(), with: TrackVideoResource.URLPlaceholderString)
        return json
    }
    
    static let URLPlaceholderString = "<NSHomeDirectory>"
    static let AssetURLKey = "AssetURLKey"
    required init(with json: [String: Any]?) {
        assetURL = URL(fileURLWithPath: "")
        super.init(with: json)
        
        guard let json = json else { return }
        guard let urlString = json[TrackVideoResource.AssetURLKey] as? String else {
            return
        }
        let convertStr = urlString.replacingOccurrences(of: TrackVideoResource.URLPlaceholderString, with: NSHomeDirectory())
        guard let url = URL(string: convertStr) else {
            return
        }
        assetURL = url
    }
}
