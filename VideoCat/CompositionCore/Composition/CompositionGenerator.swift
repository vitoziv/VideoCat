//
//  CompositionGenerator.swift
//  VideoCat
//
//  Created by Vito on 13/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class CompositionGenerator {
    
    private var increasementTrackID: Int32 = 0
    func generateNextTrackID() -> Int32 {
        let trackID = increasementTrackID + 1
        increasementTrackID = trackID
        return trackID
    }
    
    private var mainVideoTrackInfo: [AVCompositionTrack: TrackItem] = [:]
    private var mainAudioTrackInfo: [AVCompositionTrack: TrackItem] = [:]
    
    var timeline: Timeline
    
    init(timeline: Timeline) {
        self.timeline = timeline
    }
    
    func buildPlayerItem() -> AVPlayerItem {
        let composition = buildComposition()
        let playerItem = AVPlayerItem(asset: composition)
        playerItem.videoComposition = buildVideoComposition(with: composition)
        playerItem.audioMix = buildAudioMix(with: composition)
        return playerItem
    }
    
    func buildImageGenerator() -> AVAssetImageGenerator {
        let composition = buildComposition()
        let imageGenerator = AVAssetImageGenerator(asset: composition)
        imageGenerator.videoComposition = buildVideoComposition(with: composition)
        
        return imageGenerator
    }
    
    func buildExportSession()  {
        // TODO: 导出
    }
    
    private func buildComposition() -> AVMutableComposition {
        increasementTrackID = 0
        let composition = AVMutableComposition(urlAssetInitializationOptions: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        
        timeline.trackItems.forEach { (trackItem) in
            let insertTime = trackItem.configuration.timelineTimeRange.start
            
            // Main video and audio
            if let asset = trackItem.resource.trackAsset {
                if let track = asset.tracks(withMediaType: .video).first {
                    let trackID: Int32 = generateNextTrackID()
                    let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: trackID)
                    if let compositionTrack = compositionTrack {
                        self.mainVideoTrackInfo[compositionTrack] = trackItem
                        compositionTrack.preferredTransform = track.preferredTransform
                        do {
                            try compositionTrack.insertTimeRange(trackItem.resource.timeRange, of: track, at: insertTime)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                asset.tracks.filter({ $0.mediaType == .audio }).enumerated().forEach({ (offset, track) in
                    // If audio bitrate is different, can't put them on the same track, otherwise, the compositor can't handle audio play rate.
                    let trackID: Int32 = generateNextTrackID()
                    let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType, preferredTrackID: trackID)
                    if let compositionTrack = compositionTrack {
                        self.mainAudioTrackInfo[compositionTrack] = trackItem
                        compositionTrack.trackItem = trackItem
                        do {
                            try compositionTrack.insertTimeRange(trackItem.resource.timeRange, of: track, at: insertTime)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                })
            }
            
            // Other track. exp: overlay, image, video
        }
        
        return composition
    }
    
    fileprivate func buildVideoComposition(with composition: AVComposition) -> AVMutableVideoComposition? {
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = timeline.renderSize
        
        let videoTracks = composition.tracks(withMediaType: .video)
        
        let trackIDs = mainVideoTrackInfo.keys.map({ $0.trackID })
        let timeRange: CMTimeRange = {
            var duration = kCMTimeZero
            if let time = videoTracks.max(by: { $0.timeRange.end < $1.timeRange.end })?.timeRange.end {
                duration = time
            }
            return CMTimeRangeMake(kCMTimeZero, duration)
        }()
        let instruction = VideoCompositionInstruction(theSourceTrackIDs: trackIDs as [NSValue], forTimeRange: timeRange)
        instruction.mainTrackIDs = mainVideoTrackInfo.keys.map({ $0.trackID })
        
        var layerInstructions: [VideoCompositionLayerInstruction] = []
        videoTracks.forEach { (track) in
            if let trackItem = mainVideoTrackInfo[track] {
                let layerInstruction = VideoCompositionLayerInstruction(trackID: track.trackID, trackItem: trackItem)
                layerInstruction.timeRange = trackItem.configuration.timelineTimeRange
                layerInstruction.trackItem = trackItem
                layerInstructions.append(layerInstruction)
            }
            
            // TODO: Other video overlay
        }
        instruction.layerInstructions = layerInstructions
        videoComposition.instructions = [instruction]
        videoComposition.customVideoCompositorClass = VideoCompositor.self
        
        return videoComposition
    }
    
    fileprivate func buildAudioMix(with composition: AVComposition) -> AVMutableAudioMix? {
        var audioParameters = [AVMutableAudioMixInputParameters]()
        let audioTracks = composition.tracks(withMediaType: .audio)
        // 没法像 instruction 一样，可以动态的修改处理行为。所以这里只能提前设置好指定的行为
        // 动态行为，可以放到 audio tap 里
        
        audioTracks.forEach { (track) in
            if let trackItem = mainAudioTrackInfo[track] {
                // Main track, should apply transition
                let inputParameter = AVMutableAudioMixInputParameters(track: track)
                let volume = trackItem.configuration.audioConfiguration.volume
                inputParameter.setVolumeRamp(fromStartVolume: volume, toEndVolume: volume, timeRange: trackItem.configuration.timelineTimeRange)
                inputParameter.audioProcessingTapHolder = trackItem.configuration.audioConfiguration.audioTapHolder
                audioParameters.append(inputParameter)
            }
        }
        if audioParameters.count == 0 {
            return nil
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = audioParameters
        return audioMix
    }
    
}

extension AVCompositionTrack {
    
    private static var trackItemsAssociationKey: UInt8 = 0
    var trackItem: TrackItem? {
        get {
            return objc_getAssociatedObject(self, &AVCompositionTrack.trackItemsAssociationKey) as? TrackItem
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AVCompositionTrack.trackItemsAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
}

extension AVMutableAudioMixInputParameters {
    private static var audioProcessingTapHolderKey: UInt8 = 0
    var audioProcessingTapHolder: AudioProcessingTapHolder? {
        get {
            return objc_getAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey) as? AudioProcessingTapHolder
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AVMutableAudioMixInputParameters.audioProcessingTapHolderKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            audioTapProcessor = newValue?.tap?.takeRetainedValue()
        }
    }
}
