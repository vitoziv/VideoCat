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

    func timeLineView() -> UIView {
        return self
    }
    
    func timeLineScrollView() -> UIScrollView {
        return collectionView
    }
    
    var widthPerSecond: CGFloat {
        return actualWidthPerSecond
    }
    
}

extension VideoTimelineView: TimeRangeProvider {
    
    func timeLineView() -> UIView {
        return self
    }
    
    func timeLineScrollView() -> UIScrollView {
        return collectionView
    }
    
    var widthPerSecond: CGFloat {
        return viewModel.actualWidthPerSecond
    }
    
}
