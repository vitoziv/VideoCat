//
//  WaveformTimeRangeProvider.swift
//  VideoCat
//
//  Created by Vito on 29/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import CoreMedia

extension WaveformScrollView: TimeRangeProvider {
    
    func timeRangeAt(startValue: CGFloat, endValue: CGFloat) -> CMTimeRange {
        return CMTimeRange(start: kCMTimeZero, duration: kCMTimeZero)
    }
    
    func timeLineView() -> UIView {
        return self
    }
    
}
