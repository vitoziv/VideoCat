//
//  DisplayTriggerMachine.swift
//  VideoCat
//
//  Created by Vito on 24/12/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import QuartzCore

typealias TriggerOperation = () -> Void

final class DisplayTriggerMachine {
    private var displayLink: CADisplayLink
    private var triggerObject: DisplayTriggerObject
    
    var triggerOperation: TriggerOperation? {
        set {
            triggerObject.triggerOperation = newValue
        }
        get {
            return triggerObject.triggerOperation
        }
    }
    
    var preferredFramesPerSecond: Int {
        set {
            if #available(iOS 10, *) {
                displayLink.preferredFramesPerSecond = preferredFramesPerSecond
            } else {
                displayLink.frameInterval = preferredFramesPerSecond
            }
        }
        get {
            if #available(iOS 10, *) {
                return displayLink.preferredFramesPerSecond
            } else {
                return displayLink.frameInterval
            }
        }
    }
    
    deinit {
        displayLink.invalidate()
    }
    
    init() {
        triggerObject = DisplayTriggerObject()
        displayLink = CADisplayLink(target: triggerObject, selector: #selector(triggerObject.trigger))
        displayLink.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        preferredFramesPerSecond = 30
        displayLink.isPaused = true
    }
    
    convenience init(triggerOperation: @escaping TriggerOperation) {
        self.init()
        self.triggerOperation = triggerOperation
    }
    
    func start() {
        displayLink.isPaused = false
    }
    
    func pause() {
        displayLink.isPaused = true
    }
}

fileprivate class DisplayTriggerObject {
    var triggerOperation: TriggerOperation?
    @objc func trigger() {
        triggerOperation?()
    }
}

