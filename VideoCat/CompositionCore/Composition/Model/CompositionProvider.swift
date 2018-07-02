//
//  CompositionProvider.swift
//  VideoCat
//
//  Created by Vito on 2018/6/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

public protocol CompositionTrackProvider {
    func numberOfTracks(for mediaType: AVMediaType) -> Int 
    func configure(compositionTrack: AVMutableCompositionTrack, index: Int)
}

public protocol AudioMixProvider {
    func configure(audioMixParameters: AVMutableAudioMixInputParameters)
}

public protocol VideoCompositionProvider {
    
    var timeRange: CMTimeRange { get }
    
    /// 应有图像效果
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
    /// 可以往 AnimationTool 的 Layer 上添加效果，如添加动画 layer
    func configureAnimationLayer(in layer: CALayer)
    
}

public protocol PassingThroughVideoCompositionProvider: class {
    func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage
}

public protocol VideoProvider: CompositionTrackProvider, VideoCompositionProvider {}
public protocol AudioProvider: CompositionTrackProvider, AudioMixProvider { }

public protocol TransitionableVideoProvider: VideoProvider {
    var videoTransition: VideoTransition? { get }
}
