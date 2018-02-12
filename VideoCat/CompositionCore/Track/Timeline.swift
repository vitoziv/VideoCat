//
//  Timeline.swift
//  VideoCat
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

class Timeline {
    var trackItems: [TrackItem] = []
}

extension Timeline {
    
    private static let VideoTrackID_Background: Int32 = 0
    private static let VideoTrackID_1: Int32 = 1
    private static let VideoTrackID_2: Int32 = 2
    private static let AudioTrackID_1: Int32 = 3
    private static let AudioTrackID_2: Int32 = 4
    
    func buildComposition() -> AVMutableComposition {
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        var trackTime = kCMTimeZero
        trackItems.enumerated().forEach { (offset, trackItem) in
            if let asset = trackItem.resource.trackAsset {
                asset.tracks.filter({  $0.mediaType == .video || $0.mediaType == .audio }).forEach({ (track) in
                    let trackID: Int32 = {
                        if track.mediaType == .video {
                            return (offset % 2 == 0) ? Timeline.VideoTrackID_1 : Timeline.VideoTrackID_2
                        }
                        return (offset % 2 == 0) ? Timeline.AudioTrackID_1 : Timeline.AudioTrackID_2
                    }()
                    let compositionTrack: AVMutableCompositionTrack? = {
                        if let track = composition.track(withTrackID: trackID) {
                            return track
                        }
                        return composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: trackID)
                    }()
                    if let compositionTrack = compositionTrack {
                        compositionTrack.preferredTransform = track.preferredTransform
                        do {
                            try compositionTrack.insertTimeRange(trackItem.configuration.timeRange, of: track, at: trackTime)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
            
            trackTime = trackTime + trackItem.configuration.finalDuration()
        }
        
        // Add background frame
        // TODO: 使用空帧视频做填充，而不是插入空的 timeRange
        if let backgroundCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Timeline.VideoTrackID_Background) {
            let backgroundTimeRange = CMTimeRange(start: kCMTimeZero, duration: trackTime)
            backgroundCompositionTrack.insertEmptyTimeRange(backgroundTimeRange)
        }
        
        return composition
    }
    
    func buildVideoComposition() -> AVMutableVideoComposition? {
//        let videoComposition = AVMutableVideoComposition()
//
//        return videoComposition
        return nil
    }
    
    func buildAudioMix() -> AVMutableAudioMix? {
//        let audioMix = AVMutableAudioMix()
//
//        return audioMix
        return nil
    }
    
}

extension AVMutableComposition {
    func addMutableTrack(from item: TrackItem, at time: CMTime) {
        if let asset = item.resource.trackAsset {
            asset.tracks.forEach({ (t) in
                guard t.mediaType == AVMediaType.video || t.mediaType == AVMediaType.audio else {
                    return
                }
                let track: AVMutableCompositionTrack? = {
                    if let track = tracks(withMediaType: t.mediaType).first {
                        return track
                    }
                    return addMutableTrack(withMediaType: t.mediaType, preferredTrackID: t.trackID)
                }()
                track?.preferredTransform = t.preferredTransform
                if let track = track {
                    do {
                        try track.insertTimeRange(item.configuration.timeRange, of: t, at: time)
                    } catch {
                        removeTrack(track)
                        print(error.localizedDescription)
                    }
                }
            })
        }
    }
}
