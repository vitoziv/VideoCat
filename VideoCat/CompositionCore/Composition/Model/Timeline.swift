//
//  Timeline.swift
//  VideoCat
//
//  Created by Vito on 22/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import AVFoundation

public class Timeline {
    public var trackItems: [TrackItem] = []

    public var renderSize = CGSize.zero
    public var items: [MediaGroup] = []
    public var compositions: [CompositionTrackProvider] = []
    public var overlays: [CompositionTrackProvider] = []
    public var videoCompositions: [VideoCompositionProvider] = []
    public var audioCompositions: [AudioCompositionProvider] = []
}

public class MediaGroup {
    public var trackProviders: [CompositionTrackProvider] = []
    public var mediaType = AVMediaType.video // AVMediaType
    public var videoTransitions: [VideoTransition?] = []
}
