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
        timeline.videoChannel.forEach({ (provider) in
            for index in 0..<provider.numberOfTracks(for: .video) {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: trackID) {
                    provider.configure(compositionTrack: compositionTrack, index: index)
                    self.mainVideoTrackInfo[compositionTrack] = provider
                }
            }
        })
        
        timeline.audioChannel.forEach { (provider) in
            for index in 0..<provider.numberOfTracks(for: .audio) {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: trackID) {
                    provider.configure(compositionTrack: compositionTrack, index: index)
                    self.audioTrackInfo[compositionTrack] = provider
                }
            }
        }
        
        timeline.overlays.forEach { (provider) in
            for index in 0..<provider.numberOfTracks(for: .video) {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: trackID) {
                    provider.configure(compositionTrack: compositionTrack, index: index)
                    self.overlayTrackInfo[compositionTrack] = provider
                }
            }
        }
        
        timeline.audios.forEach { (provider) in
            for index in 0..<provider.numberOfTracks(for: .audio) {
                let trackID: Int32 = generateNextTrackID()
                if let compositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: trackID) {
                    provider.configure(compositionTrack: compositionTrack, index: index)
                    self.audioTrackInfo[compositionTrack] = provider
                }
            }
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
            if let provider = mainVideoTrackInfo[track] {
                let layerInstruction = VideoCompositionLayerInstruction.init(trackID: track.trackID, videoCompositionProvider: provider)
                layerInstruction.timeRange = provider.timeRange
                layerInstruction.transition = provider.videoTransition
                layerInstructions.append(layerInstruction)
            } else if let provider = overlayTrackInfo[track] {
                // Other video overlay
                let layerInstruction = VideoCompositionLayerInstruction.init(trackID: track.trackID, videoCompositionProvider: provider)
                layerInstruction.timeRange = provider.timeRange
                layerInstructions.append(layerInstruction)
            }
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
            instruction.passingThroughVideoCompositionProvider = timeline.passingThroughVideoCompositionProvider
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
        audioTracks.forEach { (track) in
            if let provider = audioTrackInfo[track] {
                let inputParameter = AVMutableAudioMixInputParameters(track: track)
                provider.configure(audioMixParameters: inputParameter)
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
    
    private var mainVideoTrackInfo: [AVCompositionTrack: TransitionableVideoProvider] = [:]
    private var overlayTrackInfo: [AVCompositionTrack: VideoProvider] = [:]
    private var audioTrackInfo: [AVCompositionTrack: AudioProvider] = [:]
    
    private func resetSetupInfo() {
        increasementTrackID = 0
        mainVideoTrackInfo = [:]
        overlayTrackInfo = [:]
        audioTrackInfo = [:]
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
            audioTapProcessor = newValue?.tap
        }
    }
}

