//
//  AudioProcessingChain.swift
//  VideoCat
//
//  Created by Vito on 2018/6/30.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

protocol AudioProcessingNode: class {
    var next: AudioProcessingNode? { get }
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>)
}

class BaseAudioProcessingNode: AudioProcessingNode {
    var next: AudioProcessingNode?
    
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) { }
}

class VolumeAudioProcessingNode: BaseAudioProcessingNode {
    
    override func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        // TODO: 支持音频的转场设置
        // 音量从小变大算法
        if timeRange.duration.isValid && timeRange.start.seconds < 2 {
            var volume: Float = 1
            volume = volume * Float(timeRange.start.seconds / 2)
            AudioMixer.changeVolume(for: bufferListInOut, volume: volume)
        }
    }
}

class AudioProcessingChain {
    var node: AudioProcessingNode?
    init(node: AudioProcessingNode) {
        self.node = node
    }
    
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        var nextNode = node
        while nextNode != nil {
            nextNode?.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
            nextNode = nextNode?.next
        }
    }
}
