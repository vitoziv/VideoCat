//
//  RangeContentView.swift
//  XDtv
//
//  Created by Vito on 08/01/2018.
//  Copyright © 2018 xiaodao.tv. All rights reserved.
//

import UIKit
import AVFoundation

class RangeContentView: UIView {
    
    var canLoadImageAsync = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        rccommonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        rccommonInit()
    }
    
    private func rccommonInit() {
        clipsToBounds = true
    }

    /// Asset's selected timerange
    var startTime: CMTime = kCMTimeZero {
        didSet {
            timeDidChange()
        }
    }
    var endTime: CMTime = kCMTimeZero{
        didSet {
            timeDidChange()
        }
    }
    
    var supportUnlimitTime: Bool = false
    var widthPerSecond: CGFloat = 10
    /// Preload left and right image thumb, if preloadCount is 2, then will preload 2 left image thumbs and 2 right image thumbs
    var preloadCount: Int = 0
    
    /// Can choose time range
    var minDuration = CMTime(seconds: 0.5)
    var maxDuration = kCMTimeIndefinite
    
    var contentWidth: CGFloat {
        let duration = endTime.seconds - startTime.seconds - leftInsetDuration.seconds - rightInsetDuration.seconds
        return CGFloat(duration) * widthPerSecond
    }
    
    var leftInsetDuration: CMTime = kCMTimeZero
    var rightInsetDuration: CMTime = kCMTimeZero

    func reachEnd() -> Bool {
        if supportUnlimitTime {
            return false
        }
        
        if endTime >= (maxDuration - CMTimeMake(1, 30)) {
            return true
        }
        
        return false
    }
    
    func reachHead() -> Bool {
        if supportUnlimitTime {
            return false
        }
        
        if startTime <= (kCMTimeZero +  CMTimeMake(1, 30)) {
            return true
        }
        
        return false
    }
    
    func expand(contentWidth: CGFloat, left: Bool) {
        let seconds = contentWidth / widthPerSecond
        if supportUnlimitTime {
            if left {
                var startSeconds = startTime.seconds - Double(seconds)
                startSeconds = min(startSeconds, endTime.seconds - minDuration.seconds)
                startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
            } else {
                let endSeconds = max(endTime.seconds + Double(seconds), startTime.seconds + minDuration.seconds)
                endTime = CMTime(seconds: endSeconds, preferredTimescale: 600)
            }
        } else {
            if left {
                var startSeconds = max(0, startTime.seconds - Double(seconds))
                startSeconds = min(startSeconds, endTime.seconds - minDuration.seconds)
                startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
            } else {
                let maxDuration: Double = self.maxDuration.seconds
                let endSeconds = max(min(endTime.seconds + Double(seconds), maxDuration), startTime.seconds + minDuration.seconds)
                endTime = CMTime(seconds: endSeconds, preferredTimescale: 600)
            }
        }
    }
    
    func endExpand() {
        if supportUnlimitTime {
            let startTime = self.startTime
            self.startTime = kCMTimeZero
            self.endTime = self.endTime - startTime
        }
    }
    
    func reloadData() {
        // subclass override
    }
    
    func updateDataIfNeed() {
        // subclass override
    }
    
    func timeDidChange() {
        // bounds offset, let images show on the right place
        let xOffset = CGFloat(startTime.seconds + leftInsetDuration.seconds) * widthPerSecond
        var offsetBounds = bounds
        offsetBounds.origin.x = xOffset
        bounds = offsetBounds
    }
    
}
