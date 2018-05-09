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
    
    private var increasementTrackID: Int32 = 0
    func generateNextTrackID() -> Int32 {
        let trackID = increasementTrackID + 1
        increasementTrackID = trackID
        return trackID
    }
    
    var timeline: Timeline
    
    init(timeline: Timeline) {
        self.timeline = timeline
    }
    
    func buildPlayerItem() -> AVPlayerItem {
        let composition = buildComposition()
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = buildVideoComposition(with: composition)
//        playerItem.audioMix = buildAudioMix(with: composition)
        return playerItem
    }
    
    func buildImageGenerator() -> AVAssetImageGenerator {
        let composition = buildComposition()
        let imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator.videoComposition = buildVideoComposition(with: composition)
        
        return imageGenerator
    }
    
    private var transitionTimeRanges: [CMTimeRange] = []
    
    private func generateTime(handler: (_ index: Int, _ item: TrackItem, _ trackTime: CMTime, _ previousTransitionDuration: CMTime) -> Void) {
        var trackTime = kCMTimeZero
        var previousTransitionDuration = kCMTimeZero
        for index in 0..<timeline.trackItems.count {
            let trackItem = timeline.trackItems[index]
            
            // Precedence: the previous transition has priority. If clip doesn't have enough time to have begin transition and end transition, then begin transition will be considered first.
            var transitionDuration: CMTime = {
                if let duration = trackItem.transition?.duration {
                    return duration
                }
                return kCMTimeZero
            }()
            let trackDuration = trackItem.configuration.timelineDuration()
            if trackDuration < transitionDuration {
                transitionDuration = kCMTimeZero
            } else {
                if index < timeline.trackItems.count - 1 {
                    let nextTrackItem = timeline.trackItems[index + 1]
                    if nextTrackItem.configuration.timelineDuration() < transitionDuration {
                        transitionDuration = kCMTimeZero
                    }
                } else {
                    transitionDuration = kCMTimeZero
                }
            }
            
            trackTime = trackTime - previousTransitionDuration
            
            handler(index, trackItem, trackTime, previousTransitionDuration)
            
            previousTransitionDuration = transitionDuration
            trackTime = trackTime + trackDuration
        }
    }
    
    func buildComposition() -> AVMutableComposition {
        increasementTrackID = 0
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        var mainVideoTrackIDs = [Int: Int32]()
        var mainAudioTrackIDs: [Int :[Int: Int32]] = [:]
        generateTime { (index, trackItem, trackTime, previousTransitionDuration) in
            let insertTime = trackTime
            if let asset = trackItem.resource.trackAsset {
                if let track = asset.tracks(withMediaType: .video).first {
                    let trackID: Int32 = {
                        let idIndex = index % 2
                        if let trackID = mainVideoTrackIDs[idIndex] {
                            return trackID
                        } else {
                            let trackID = generateNextTrackID()
                            mainVideoTrackIDs[idIndex] = trackID
                            return trackID
                        }
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
                }
                asset.tracks.filter({ $0.mediaType == .audio }).enumerated().forEach({ (offset, track) in
                    let trackID: Int32 = {
                        let idIndex = index % 2
                        if let trackID = mainAudioTrackIDs[offset]?[idIndex] {
                            return trackID
                        } else {
                            let trackID = generateNextTrackID()
                            if var offsetTrackIDS = mainAudioTrackIDs[offset] {
                                offsetTrackIDS[idIndex] = trackID
                                mainAudioTrackIDs[offset] = offsetTrackIDS
                            } else {
                                mainAudioTrackIDs[offset] = [idIndex: trackID]
                            }
                            return trackID
                        }
                    }()
                    let compositionTrack: AVMutableCompositionTrack? = {
                        if let track = composition.track(withTrackID: trackID) {
                            return track
                        }
                        return composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: trackID)
                    }()
                    if let compositionTrack = compositionTrack {
                        do {
                            try compositionTrack.insertTimeRange(trackItem.configuration.timeRange, of: track, at: insertTime)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
        }
        
        var trackGroups: [TrackGroup] = []
        
        let videoTrackGroup = TrackGroup()
        videoTrackGroup.trackIDs = mainVideoTrackIDs.keys.sorted(by: <).map({ mainVideoTrackIDs[$0]! })
        videoTrackGroup.mediaType = .video
        trackGroups.append(videoTrackGroup)
        
        mainAudioTrackIDs.forEach { (offset, trackIDs) in
            let trackGroup = TrackGroup()
            let groupIDS = trackIDs.keys.sorted(by: <).map({ trackIDs[$0]! })
            trackGroup.trackIDs = groupIDS
            trackGroup.mediaType = .audio
            trackGroups.append(trackGroup)
        }
        
        composition.mainTrackGroups = trackGroups
        
        return composition
    }
    
    func buildVideoComposition(with composition: AVComposition) -> AVMutableVideoComposition? {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = timeline.renderSize
        
        let videoTracks = composition.tracks(withMediaType: .video)
        
        let trackIDs = videoTracks.map({ $0.trackID })
        let timeRange: CMTimeRange = {
            var duration = kCMTimeZero
            if let time = videoTracks.max(by: { $0.timeRange.end < $1.timeRange.end })?.timeRange.end {
                duration = time
            }
            return CMTimeRangeMake(kCMTimeZero, duration)
        }()
        let instruction = VideoCompositionInstruction(theSourceTrackIDs: trackIDs as [NSValue], forTimeRange: timeRange)
        instruction.mainTrackIDs = composition.mainTrackGroups.first(where: { $0.mediaType == .video })!.trackIDs
        
        var layerInstructions: [VideoCompositionLayerInstruction] = []
        
        generateTime { (index, trackItem, trackTime, previousTransitionDuration) in
            let trackIndex = index % 2
            let track = videoTracks[trackIndex]
            let trackDuration = trackItem.configuration.timelineDuration()
            let timeRange = CMTimeRangeMake(trackTime, trackDuration)
            let layerInstruction = VideoCompositionLayerInstruction(trackID: track.trackID, trackItem: trackItem)
            layerInstruction.timeRange = timeRange
            layerInstruction.trackItem = trackItem
            layerInstructions.append(layerInstruction)
        }
        instruction.layerInstructions = layerInstructions
        videoComposition.instructions = [instruction]
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        
        return videoComposition
    }
    
    public func buildAudioMix(with asset: AVAsset) -> AVMutableAudioMix? {
        var audioParameters = [AVMutableAudioMixInputParameters]()
        
        if audioParameters.count == 0 {
            return nil
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioParameters
        return audioMix
    }
    
    
    
}

private var trackGroupAssociationKey: UInt8 = 0

extension AVComposition {
    var mainTrackGroups: [TrackGroup] {
        get {
            if let groups = (objc_getAssociatedObject(self, &trackGroupAssociationKey) as? [TrackGroup]) {
                return groups
            } else {
                let groups = [TrackGroup]()
                self.mainTrackGroups = groups
                return groups
            }
        }
        set(newValue) {
            objc_setAssociatedObject(self, &trackGroupAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}


class TrackGroup {
    var identifier: String = ProcessInfo.processInfo.globallyUniqueString
    var mediaType: AVMediaType = .video
    var trackIDs: [Int32] = []
}

