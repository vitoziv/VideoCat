//
//  PanelViewModel.swift
//  VideoCat
//
//  Created by Vito on 28/10/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import VFCabbage

class TimelineManager {
    static let current = TimelineManager()
    var timeline = Timeline()
}

class TimelineViewModel {
    var trackItems: [TrackItem] = []
    
    var backgroundColors = TimeRangeStore<UIColor>()
    var renderSize: CGSize = {
        let width = UIScreen.main.bounds.width * UIScreen.main.scale
        let height: CGFloat = round(width * 0.5625)
        return CGSize.init(width: width, height: height)
    }()
    
    init() {
        let timeline = TimelineManager.current.timeline
        timeline.passingThroughVideoCompositionProvider = self
        let timeRange = CMTimeRange(start: CMTime.init(value: 2, 1), duration: CMTime.init(value: 2, 1))
        backgroundColors.setItem(UIColor.init(red: 0.6, green: 0.34, blue: 0.43, alpha: 1.0), timeRange: timeRange)
    }
    
    private(set) var playerItem = AVPlayerItem(asset: AVComposition.init())
    
    func addTrackItem(_ trackItem: TrackItem) {
        performUpdate {
            trackItems.append(trackItem)
        }
        reloadPlayerItem()
    }
    
    func insertTrackItem(_ tackItem: TrackItem, at index: Int) {
        performUpdate {
            trackItems.insert(tackItem, at: index)
        }
        reloadPlayerItem()
    }
    
    func timeRange(at index: Int) -> CMTimeRange {
        var startTime = kCMTimeZero
        for i in (0..<index) {
            let trackItem = trackItems[i]
            startTime = CMTimeAdd(startTime, trackItem.resourceTargetTimeRange.duration)
        }
        if index >= trackItems.count {
            return CMTimeRangeMake(startTime, kCMTimeZero)
        }
        let trackItem = trackItems[index]
        return trackItem.resourceTargetTimeRange
    }
    
    func reloadPlayerItem() {
        let timeline = TimelineManager.current.timeline
        reloadTimeline(timeline)
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = renderSize
        let playerItem = compositionGenerator.buildPlayerItem()
        self.playerItem = playerItem
    }
    
    fileprivate func reloadTimeline(_ timeline: Timeline) {
        timeline.videoChannel = trackItems
        timeline.audioChannel = trackItems
    }
    
    func buildTimeline() -> Timeline {
        let timeline = TimelineManager.current.timeline
        reloadTimeline(timeline)
        return timeline
    }
    
}

// MARK: - Reload Timeline

extension TimelineViewModel {
    func performUpdate(_ updateBlock: () -> Void) {
        updateBlock()
        reloadTimelineTimeRange()
    }
    
    func reloadTimelineTimeRange() {
        reloadTimelineDuration()
        Timeline.reloadVideoStartTime(providers: trackItems)
    }
    
    private func reloadTimelineDuration() {
        trackItems.forEach({ $0.reloadTimelineDuration() })
    }
}

extension TimelineViewModel: PassingThroughVideoCompositionProvider {
    public func applyEffect(to sourceImage: CIImage, at time: CMTime, renderSize: CGSize) -> CIImage {
        var image = sourceImage
        
        let backgroundColorItems = backgroundColors.getItems(at: time)
        if let item = backgroundColorItems.last {
            let backgroundColor = CIColor(color: item.1)
            let backgroundImage = CIImage(color: backgroundColor).cropped(to: CGRect(origin: .zero, size: renderSize))
            image = image.composited(over: backgroundImage)
        }
        return image
    }
}

