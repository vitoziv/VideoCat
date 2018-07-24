//
//  TrackItem.swift
//  VideoCat
//
//  Created by Vito on 21/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation
import CoreImage

public class TrackItem: NSObject, NSCopying {
    
    public var identifier: String
    public var resource: Resource
    public var configuration: TrackConfiguration
    
    public var videoTransition: VideoTransition?
    public var audioTransition: AudioTransition?
    
    public required init(resource: Resource) {
        identifier = ProcessInfo.processInfo.globallyUniqueString
        self.resource = resource
        configuration = TrackConfiguration()
        super.init()
    }
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let item = type(of: self).init(resource: resource.copy() as! Resource)
        item.identifier = identifier
        item.configuration = configuration.copy() as! TrackConfiguration
        item.videoTransition = videoTransition
        item.audioTransition = audioTransition
        return item
    }
}

public extension TrackItem {
    func reloadTimelineDuration() {
        let duration = resource.selectedTimeRange.duration
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
        if let resource = resource as? TrackResource {
            return resource.numberOfTracks(for: mediaType)
        } else if resource.isMember(of: ImageResource.self) {
            if mediaType == .video {
                return 1
            }
        }
        
        return 0
    }
    
    private static let emptyAsset: AVAsset = {
        let url = Bundle.main.url(forResource: "black_empty", withExtension: "mp4")!
        let asset = AVAsset(url: url)
        return asset
    }()
    
    public func compositionTrack(for composition: AVMutableComposition, at index: Int, mediaType: AVMediaType, preferredTrackID: Int32) -> AVCompositionTrack? {
        let videoTrack: AVAssetTrack? = {
            if let resource = resource as? TrackResource {
                return resource.track(at: index, mediaType: mediaType)
            } else if resource.isMember(of: ImageResource.self) {
                if mediaType == .video {
                    return TrackItem.emptyAsset.tracks(withMediaType: mediaType).first
                }
            }
            return nil
        }()
        guard let track = videoTrack else {
            return nil
        }
        
        let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: preferredTrackID)
        if let compositionTrack = compositionTrack {
            if compositionTrack.mediaType == .video {
                compositionTrack.preferredTransform = track.preferredTransform
            }
            do {
                try compositionTrack.insertTimeRange(resource.selectedTimeRange, of: track, at: timeRange.start)
            } catch {
                Log.error(#function + error.localizedDescription)
            }
        }
        return compositionTrack
    }
    
}

extension TrackItem: VideoCompositionProvider {
    
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var finalImage: CIImage = {
            if let resource = resource as? ImageResource,
                let resourceImage = resource.image(at: time, renderSize: renderSize) {
                return resourceImage
            }
            return sourceImage
        }()
        
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
        
        if let filterProcessor = configuration.videoConfiguration.filterProcessor {
            finalImage = filterProcessor(finalImage)
        }
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
        audioMixParameters.audioProcessingTapHolder = configuration.audioConfiguration.audioTapHolder
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

extension TrackItem {
    func generateFullRangeImageGenerator(size: CGSize = .zero) -> AVAssetImageGenerator? {
        let item = self.copy() as! TrackItem
        let imageGenerator = AVAssetImageGenerator.createFullRangeGenerator(from: item)
        imageGenerator?.updateAspectFitSize(size)
        return imageGenerator
    }
    
    func generateFullRangePlayerItem(size: CGSize = .zero) -> AVPlayerItem? {
        let item = self.copy() as! TrackItem
        item.resource.selectedTimeRange = CMTimeRange.init(start: kCMTimeZero, duration: item.resource.duration)
        
        let timeline = Timeline()
        timeline.videoChannel = [item]
        timeline.audioChannel = [item]
        let generator = CompositionGenerator(timeline: timeline)
        generator.renderSize = size
        let playerItem = generator.buildPlayerItem()
        return playerItem
    }
}

