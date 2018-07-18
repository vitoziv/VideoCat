//
//  AudioProcessingChain.swift
//  VideoCat
//
//  Created by Vito on 2018/6/30.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

protocol AudioProcessingNode: class {
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>)
}

class VolumeAudioProcessingNode: AudioProcessingNode {
    
    var timeRange: CMTimeRange
    var startVolume: Float
    var endVolume: Float
    var timingFunction: ((Double) -> Double)?
    init(timeRange: CMTimeRange, startVolume: Float, endVolume: Float) {
        self.timeRange = timeRange
        self.startVolume = startVolume
        self.endVolume = endVolume
    }
    
     func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        if timeRange.duration.isValid {
            if self.timeRange.intersection(timeRange).duration.seconds > 0 {
                var percent = (timeRange.end.seconds - self.timeRange.start.seconds) / self.timeRange.duration.seconds
                if let timingFunction = timingFunction {
                    percent = timingFunction(percent)
                }
                let volume = startVolume + (endVolume - startVolume) * Float(percent)
                AudioMixer.changeVolume(for: bufferListInOut, volume: volume)
            }
        }
    }
    
}

class AudioProcessingChain {
    var nodes: [AudioProcessingNode] = []
    
    func process(timeRange: CMTimeRange, bufferListInOut: UnsafeMutablePointer<AudioBufferList>) {
        nodes.forEach { (node) in
            node.process(timeRange: timeRange, bufferListInOut: bufferListInOut)
        }
    }
}
