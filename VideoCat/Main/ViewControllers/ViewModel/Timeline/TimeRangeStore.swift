//
//  TimeRangeStore.swift
//  VideoCat
//
//  Created by Vito on 2018/6/25.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreMedia

public class TimeRangeStore<T> {
    
    public init() {}
    
    private(set) var data: [(CMTimeRange, T)] = []
    
    public func setItem(_ item: T, timeRange: CMTimeRange, at index: Int = -1) {
        if index >= 0, index < data.count {
            data.insert((timeRange, item), at: index)
        } else {
            data.append((timeRange, item))
        }
    }
    
    @discardableResult
    public func remove(at index: Int) -> (CMTimeRange, T) {
        return data.remove(at: index)
    }
    
    public func getItems(at time: CMTime) -> [(CMTimeRange, T)] {
        var result = [(CMTimeRange, T)]()
        data.forEach { (item) in
            if item.0.containsTime(time) {
                result.append(item)
            }
        }
        
        return result
    }
    
    public func getItems(at timeRange: CMTimeRange) -> [(CMTimeRange, T)] {
        var result = [(CMTimeRange, T)]()
        data.forEach { (item) in
            if item.0.intersection(timeRange).duration.seconds > 0 {
                result.append(item)
            }
        }
        
        return result
    }
    
}
