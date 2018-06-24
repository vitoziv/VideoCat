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
    public var renderSize = CGSize.zero
    public var passingThroughVideoCompositionProvider: PassingThroughVideoCompositionProvider?
    
    // MARK: - Main content, arranged in order, support transition.
    public var videoChannel: [TransitionableVideoProvider] = []
    public var audioChannel: [AudioChannel] = []
    
    // MARK: - Other content, can place anywhere in timeline
    public var overlays: [VideoProvider] = []
    public var audios: [AudioProvider] = []
    
    
}

public class AudioChannel {
    public var channelIdentifier: String = ""
    public var audioProviders: [TransitionableAudioProvider] = []
}


