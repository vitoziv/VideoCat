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
    
    private var transitionTimeRanges: [CMTimeRange] = []
    
    func buildComposition() -> AVMutableComposition {
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        var trackTime = kCMTimeZero
        var previousTransitionDuration = kCMTimeZero
        for index in 0..<timeline.trackItems.count {
            let trackItem = timeline.trackItems[index]
            
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration = trackItem.transition.duration
            let trackDuration = trackItem.configuration.finalDuration() - previousTransitionDuration
            if trackDuration < transitionDuration {
                transitionDuration = kCMTimeZero
            } else {
                if index < timeline.trackItems.count - 1 {
                    let nextTrackItem = timeline.trackItems[index + 1]
                    if nextTrackItem.configuration.finalDuration() < transitionDuration {
                        transitionDuration = kCMTimeZero
                    }
                } else {
                    transitionDuration = kCMTimeZero
                }
            }
            
            let insertTime = trackTime - previousTransitionDuration
            if let asset = trackItem.resource.trackAsset {
                asset.tracks.filter({  $0.mediaType == .video || $0.mediaType == .audio }).forEach({ (track) in
                    let trackID: Int32 = {
                        if track.mediaType == .video {
                            return (index % 2 == 0) ? CompositionGenerator.VideoTrackID_1 : CompositionGenerator.VideoTrackID_2
                        }
                        return (index % 2 == 0) ? CompositionGenerator.AudioTrackID_1 : CompositionGenerator.AudioTrackID_2
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
                            try compositionTrack.insertTimeRange(trackItem.configuration.timeRange, of: track, at: insertTime)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
            
            previousTransitionDuration = transitionDuration
            trackTime = trackTime + trackDuration
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
        // TODO: 实现转场插入
        
        
        var previousTransitionDuration = kCMTimeZero
        for index in 0..<timeline.trackItems.count {
            let trackItem = timeline.trackItems[index]
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration = trackItem.transition.duration
            let trackDuration = trackItem.configuration.finalDuration() - previousTransitionDuration
            
            if trackDuration < transitionDuration {
                transitionDuration = kCMTimeZero
            } else {
                if index < timeline.trackItems.count - 1 {
                    let nextTrackItem = timeline.trackItems[index + 1]
                    if nextTrackItem.configuration.finalDuration() < transitionDuration {
                        transitionDuration = kCMTimeZero
                    }
                } else {
                    transitionDuration = kCMTimeZero
                }
            }
            
            let trackIndex = index % 2
            let track = videoTracks[trackIndex]
            let trackCenterDuration = trackDuration - transitionDuration
            let timeRange = CMTimeRangeMake(trackTime, trackCenterDuration)
            let instruction = VIVideoCompositionInstruction(theSourceTrackIDs: [track.trackID as NSValue], forTimeRange: timeRange)
            instruction.transition = CrossDissolveTransition()
            let layerInstruction = VIVideoCompositionLayerInstruction(assetTrack: track)
            layerInstruction.trackItem = trackItem
            instruction.layerInstructions = [layerInstruction]
            instructions.append(instruction)
            
            if transitionDuration.seconds > 0 && index < timeline.trackItems.count - 1 {
                let nextTrackIndex = (index + 1) % 2
                let nextTrack = videoTracks[nextTrackIndex]
                let startTime = trackTime + trackCenterDuration
                let timeRange = CMTimeRangeMake(startTime, transitionDuration)
                let instruction = VIVideoCompositionInstruction(theSourceTrackIDs: [track.trackID as NSValue, nextTrack.trackID as NSValue], forTimeRange: timeRange)
                instruction.foregroundTrackID = nextTrack.trackID
                instruction.backgroundTrackID = track.trackID
                instruction.transition = trackItem.transition
                let layerInstruction = VIVideoCompositionLayerInstruction(assetTrack: track)
                layerInstruction.trackItem = trackItem
                let nextLayerInstruction = VIVideoCompositionLayerInstruction(assetTrack: nextTrack)
                let nextTrackItem = timeline.trackItems[index + 1]
                nextLayerInstruction.trackItem = nextTrackItem
                instruction.layerInstructions = [layerInstruction, nextLayerInstruction]
                instructions.append(instruction)
            }
            
            previousTransitionDuration = transitionDuration
            trackTime = trackTime + trackDuration
        }
        
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        
        videoComposition.instructions = instructions
        return videoComposition
    }
    
    func buildAudioMix() -> AVMutableAudioMix? {
        return nil
    }
    
}
