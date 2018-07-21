//
//  Timeline.swift
//  VideoCat
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class Timeline {

    // MARK: - Global effect
    public var passingThroughVideoCompositionProvider: PassingThroughVideoCompositionProvider?
    
    // MARK: - Main content, support transition.
    public var videoChannel: [TransitionableVideoProvider] = []
    public var audioChannel: [TransitionableAudioProvider] = []
    
    // MARK: - Other content, can place anywhere in timeline
    public var overlays: [VideoProvider] = []
    public var audios: [AudioProvider] = []
    
}
