//
//  CompositionProvider.swift
//  VideoCat
//
//  Created by Vito on 2018/6/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreImage
import AVFoundation

public protocol CompositionTimeRangeProvider {
    var timeRange: CMTimeRange { get set }
}

public protocol VideoCompositionTrackProvider: CompositionTimeRangeProvider {
    func numberOfVideoTracks() -> Int
    func videoCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioCompositionTrackProvider: CompositionTimeRangeProvider {
    func numberOfAudioTracks() -> Int
    func audioCompositionTrack(for composition: AVMutableComposition, at index: Int, preferredTrackID: Int32) -> AVCompositionTrack?
}

public protocol AudioMixProvider {
    func configure(audioMixParameters: AVMutableAudioMixInputParameters)
}

public protocol VideoCompositionProvider {
    
    /// 应有图像效果
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
    /// 可以往 AnimationTool 的 Layer 上添加效果，如添加动画 layer
    func configureAnimationLayer(in layer: CALayer)
    
}

public protocol PassingThroughVideoCompositionProvider: class {
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
}

public protocol VideoProvider: VideoCompositionTrackProvider, VideoCompositionProvider {}
public protocol AudioProvider: AudioCompositionTrackProvider, AudioMixProvider { }

public protocol TransitionableVideoProvider: VideoProvider {
    var videoTransition: VideoTransition? { get }
}
public protocol TransitionableAudioProvider: AudioProvider {
    var audioTransition: AudioTransition? { get }
}
