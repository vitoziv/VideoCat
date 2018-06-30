//
//  AudioTransition.swift
//  VideoCat
//
//  Created by Vito on 2018/6/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

open class AudioTransition {
    
    public var identifier: String
    open var duration: CMTime
    
    public var previousAudioMixEndVolume: Float
    public var nextAudioMixStartVolume: Float
    
    public init(duration: CMTime = kCMTimeZero) {
        self.identifier = ""
        self.duration = duration
        self.previousAudioMixEndVolume = 0
        self.nextAudioMixStartVolume = 0
    }
    
}
