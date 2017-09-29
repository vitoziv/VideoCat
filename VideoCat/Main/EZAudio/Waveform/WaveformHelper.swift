//
//  WaveformHelper.swift
//  VideoCat
//
//  Created by Vito on 28/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation

struct PointInfo {
    var points: UnsafeMutablePointer<CGPoint>?
    var pointCount: Int
    
    init(pointCount: Int = 64) {
        self.pointCount = pointCount
        let bit = MemoryLayout<CGPoint>.stride * pointCount
        points = UnsafeMutablePointer.allocate(capacity: bit)
    }
}
