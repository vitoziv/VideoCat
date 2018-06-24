//
//  AudioTransition.swift
//  VideoCat
//
//  Created by Vito on 2018/6/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

public protocol AudioTransition: class {
    var identifier: String { get }
    var duration: CMTime { get }
    func apply(foregroundAudioMix: AVMutableAudioMixInputParameters, backgroundAudioMix: AVMutableAudioMixInputParameters)
}
