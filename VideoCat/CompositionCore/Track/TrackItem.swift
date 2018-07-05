//
//  TrackItem.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class TrackItem {
    
    public var identifier: String
    public var resource: TrackResource
    public var configuration: TrackConfiguration
    
    public var videoTransition: VideoTransition?
    public var audioTransition: AudioTransition?
    
    init(resource: TrackResource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
    }
    
}

public extension TrackItem {
    func reloadTimelineDuration() {
        let duration = resource.timeRange.duration
        var timeRange = configuration.timelineTimeRange
        timeRange.duration = duration
        configuration.timelineTimeRange = timeRange
    }
}

extension TrackItem: CompositionTrackProvider {
    
    public var timeRange: CMTimeRange {
        return configuration.timelineTimeRange
    }
    
    public func numberOfTracks(for mediaType: AVMediaType) -> Int {
        if let asset = resource.trackAsset {
            return asset.tracks(withMediaType: mediaType).count
        }
        return 0
    }
    
    public func configure(compositionTrack: AVMutableCompositionTrack, index: Int) {
        if let asset = resource.trackAsset {
            func insertTrackToCompositionTrack(_ track: AVAssetTrack) {
                do {
                    try compositionTrack.insertTimeRange(resource.timeRange, of: track, at: timeRange.start)
                } catch {
                    Log.error(error.localizedDescription)
                }
            }
            if compositionTrack.mediaType == .video {
                if let track = asset.tracks(withMediaType: .video).first {
                    compositionTrack.preferredTransform = track.preferredTransform
                    insertTrackToCompositionTrack(track)
                }
            } else if compositionTrack.mediaType == .audio {
                let tracks = asset.tracks(withMediaType: .audio)
                if tracks.count > index {
                    insertTrackToCompositionTrack(tracks[index])
                }
            }
        }
    }
    
}

extension TrackItem: VideoCompositionProvider {
    
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage = sourceImage
        guard let track = resource.trackAsset?.tracks(withMediaType: .video).first else {
            return finalImage
        }
        
        finalImage = finalImage.flipYCoordinate().transformed(by: track.preferredTransform).flipYCoordinate()
        
        var transform = CGAffineTransform.identity
        switch configuration.videoConfiguration.baseContentMode {
        case .aspectFit:
            let fitTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFitInRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fitTransform)
        case .aspectFill:
            let fillTransform = CGAffineTransform.transform(by: finalImage.extent, aspectFillRect: CGRect(origin: .zero, size: renderSize))
            transform = transform.concatenating(fillTransform)
        }
        finalImage = finalImage.transformed(by: transform)
        return finalImage
    }
    
    
    public func configureAnimationLayer(in layer: CALayer) {
        // TODO: Support animation tool layer
    }

}

extension TrackItem: AudioProvider {
    public func configure(audioMixParameters: AVMutableAudioMixInputParameters) {
        let volume = configuration.audioConfiguration.volume
        audioMixParameters.setVolumeRamp(fromStartVolume: volume, toEndVolume: volume, timeRange: configuration.timelineTimeRange)
    }
}

extension TrackItem: TransitionableVideoProvider {
    
}
extension TrackItem: TransitionableAudioProvider {
    
}


private extension CIImage {
    func flipYCoordinate() -> CIImage {
        let flipYTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: extent.origin.y * 2 + extent.height)
        return transformed(by: flipYTransform)
    }
}

