//
//  CompositionGenerator.swift
//  VideoCat
//
//  Created by Vito on 13/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class CompositionGenerator {
    
    private static let VideoTrackID_Background: Int32 = 0
    private static let VideoTrackID_1: Int32 = 1
    private static let VideoTrackID_2: Int32 = 2
    private static let AudioTrackID_1: Int32 = 3
    private static let AudioTrackID_2: Int32 = 4
    
    var timeline: Timeline
    
    init(timeline: Timeline) {
        self.timeline = timeline
    }
    
    func buildPlayerItem() -> AVPlayerItem {
        let composition = buildComposition()
        let playerItem = AVPlayerItem(asset: composition)
        // TODO: video composition
        playerItem.videoComposition = buildVideoComposition(with: composition)
        // TODO: AudioMix
        return playerItem
    }
    
    func buildImageGenerator() -> AVAssetImageGenerator {
        let composition = buildComposition()
        let imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator.videoComposition = buildVideoComposition(with: composition)
        // TODO: video composition
        // TODO: AudioMix
        
        return imageGenerator
    }
    
    func buildComposition() -> AVMutableComposition {
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        var trackTime = kCMTimeZero
        timeline.trackItems.enumerated().forEach { (offset, trackItem) in
            if let asset = trackItem.resource.trackAsset {
                asset.tracks.filter({  $0.mediaType == .video || $0.mediaType == .audio }).forEach({ (track) in
                    let trackID: Int32 = {
                        if track.mediaType == .video {
                            return (offset % 2 == 0) ? CompositionGenerator.VideoTrackID_1 : CompositionGenerator.VideoTrackID_2
                        }
                        return (offset % 2 == 0) ? CompositionGenerator.AudioTrackID_1 : CompositionGenerator.AudioTrackID_2
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
        //        if let blackEmptyAssetURL = Bundle.main.url(forResource: "black_empty", withExtension: "mp4") {
        //            let blackEmptyAsset = AVAsset(url: blackEmptyAssetURL)
        //            if let blackEmptyVideoTrack = blackEmptyAsset.tracks(withMediaType: .video).first {
        //                if let backgroundCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Timeline.VideoTrackID_Background) {
        //                    let frameDuration = CMTime(value: 1, timescale: 30)
        //                    let timeRange = CMTimeRange(start: kCMTimeZero, duration: frameDuration)
        //                    try? backgroundCompositionTrack.insertTimeRange(timeRange, of: blackEmptyVideoTrack, at: trackTime - frameDuration)
        //                }
        //            }
        //        }
        
        return composition
    }
    
    func buildVideoComposition(with composition: AVComposition) -> AVMutableVideoComposition? {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = timeline.renderSize
        var instructions: [AVVideoCompositionInstructionProtocol] = []
        
        var trackTime = kCMTimeZero
        let videoTracks = composition.tracks(withMediaType: .video)
        timeline.trackItems.enumerated().forEach { (offset, trackItem) in
            let trackIndex = offset % 2
            if videoTracks.count > trackIndex {
                let track = videoTracks[trackIndex]
                let timeRange = CMTimeRangeMake(trackTime, trackItem.configuration.finalDuration())
                let instruction = VIVideoCompositionInstruction(theSourceTrackIDs: [track.trackID as NSValue], forTimeRange: timeRange)
                let layerInstruction = VIVideoCompositionLayerInstruction(assetTrack: track)
                layerInstruction.trackItem = trackItem
                instruction.layerInstructions = [layerInstruction]
                instructions.append(instruction)
                
                trackTime = trackTime + trackItem.configuration.finalDuration()
            }
        }
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        
        videoComposition.instructions = instructions
        return videoComposition
    }
    
    func buildAudioMix() -> AVMutableAudioMix? {
        return nil
    }
    
}
