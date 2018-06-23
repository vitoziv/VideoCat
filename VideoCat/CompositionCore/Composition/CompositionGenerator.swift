//
//  CompositionGenerator.swift
//  VideoCat
//
//  Created by Vito on 13/02/2018.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

class CompositionGenerator {
    
    // MARK: - Public
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
    
    // MARK: - Build Composition
    
    private func buildComposition() -> AVMutableComposition {
        resetSetupInfo()
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
        
        // 创建多个 instruction，每个 instruction 保存当前时间所有的 layerInstruction，在渲染的时候可以直接拿到对应时间点所需要的 layerInstruction。
        var layerInstructionsSlices: [(CMTimeRange, [VideoCompositionLayerInstruction])] = []
        layerInstructions.forEach { (layerInstruction) in
            var slices = layerInstructionsSlices
            
            var leftTimeRanges: [CMTimeRange] = [layerInstruction.timeRange]
            layerInstructionsSlices.enumerated().forEach({ (offset, slice) in
                let intersectionTimeRange = slice.0.intersection(layerInstruction.timeRange)
                if intersectionTimeRange.duration.seconds > 0 {
                    slices.remove(at: offset)
                    let sliceTimeRanges = CMTimeRange.sliceTimeRanges(for: layerInstruction.timeRange, timeRange2: slice.0)
                    sliceTimeRanges.forEach({ (timeRange) in
                        if slice.0.containsTimeRange(timeRange) && layerInstruction.timeRange.containsTimeRange(timeRange) {
                            let newSlice = (timeRange, slice.1 + [layerInstruction])
                            slices.append(newSlice)
                            leftTimeRanges = leftTimeRanges.flatMap({ (leftTimeRange) -> [CMTimeRange] in
                                return leftTimeRange.substruct(timeRange)
                            })
                        } else if slice.0.containsTimeRange(timeRange) {
                            let newSlice = (timeRange, slice.1)
                            slices.append(newSlice)
                        }
                    })
                }
            })
            
            leftTimeRanges.forEach({ (timeRange) in
                slices.append((timeRange, [layerInstruction]))
            })
            
            layerInstructionsSlices = slices
        }
        let mainTrackIDs = mainVideoTrackInfo.keys.map({ $0.trackID })
        let instructions: [VideoCompositionInstruction] = layerInstructionsSlices.map({ (slice) in
            let trackIDs = slice.1.map({ $0.trackID })
            let instruction = VideoCompositionInstruction(theSourceTrackIDs: trackIDs as [NSValue], forTimeRange: slice.0)
            instruction.layerInstructions = slice.1
            instruction.mainTrackIDs = mainTrackIDs.filter({ trackIDs.contains($0) })
            return instruction
        })
        
        videoComposition.instructions = instructions
        
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
    
    // MARK: - Helper
    
    private var increasementTrackID: Int32 = 0
    private func generateNextTrackID() -> Int32 {
        let trackID = increasementTrackID + 1
        increasementTrackID = trackID
        return trackID
    }
    
    private var mainVideoTrackInfo: [AVCompositionTrack: TrackItem] = [:]
    private var mainAudioTrackInfo: [AVCompositionTrack: TrackItem] = [:]
    
    private func resetSetupInfo() {
        increasementTrackID = 0
        mainVideoTrackInfo = [:]
        mainAudioTrackInfo = [:]
    }
    
    
}

// MARK: -

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

