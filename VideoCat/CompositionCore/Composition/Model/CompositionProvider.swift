//
//  CompositionProvider.swift
//  VideoCat
//
//  Created by Vito on 2018/6/23.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

/// 可以生成 Track 时间的 clip 应该实现这个协议
public protocol CompositionTrackProvider {
    
    /// 应用片段到 track 中
    ///
    /// - Parameters:
    ///   - compositionTrack: 要应用的 track
    ///   - starPosition: 开始时间
    func applyto(compositionTrack: AVMutableCompositionTrack)
    
}

public protocol AudioCompositionProvider {
    
    /// 应用声音效果，变速、鬼畜的因素会影响
    ///
    /// - Parameters:
    ///   - audioMixParameters: 外部传入的音频配置
    ///   - startTime: 这个声音片段的开始时间
    ///   - maxDuration: 最大时间
    func applyEffectTo(audioMixParameters: AVMutableAudioMixInputParameters)
    
}

public protocol VideoCompositionProvider {
    
    /// 应用旋转、缩放、位移和滤镜效果到 layerInstruction 中
    func applyEffectTo(layerInstruction: VideoCompositionLayerInstruction, startTime: CMTime, duration: CMTime, clipSize: CGSize, renderSize: CGSize)
    
    /// 可以往 AnimationTool 的 Layer 上添加效果，如添加动画 layer
    func applyEffectTo(layer: CALayer, startTime: CMTime)
    
}
