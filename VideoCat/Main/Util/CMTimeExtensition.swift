//
//  CMTimeExtensition.swift
//  Cabbage
//
//  Created by Vito on 2018/7/19.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreMedia

// MARK: Initialization
public extension CMTime {
    public func xd_time(preferredTimeScale: Int32 = 600) -> CMTime {
        return CMTime(seconds: seconds, preferredTimescale: preferredTimeScale)
    }
}

// MARK: Add
func += ( left: inout CMTime, right: CMTime) -> CMTime {
    left = left + right
    return left
}

// MARK: Subtract
func -= ( minuend: inout CMTime, subtrahend: CMTime) -> CMTime {
    minuend = minuend - subtrahend
    return minuend
}

// MARK: Multiply
func * (time: CMTime, multiplier: Int32) -> CMTime {
    return CMTimeMultiply(time, multiplier).xd_time()
}
func * (multiplier: Int32, time: CMTime) -> CMTime {
    return CMTimeMultiply(time, multiplier).xd_time()
}
func * (time: CMTime, multiplier: Float64) -> CMTime {
    return CMTimeMultiplyByFloat64(time, multiplier).xd_time()
}
func * (time: CMTime, multiplier: Float) -> CMTime {
    return CMTimeMultiplyByFloat64(time, Float64(multiplier)).xd_time()
}
func * (multiplier: Float64, time: CMTime) -> CMTime {
    return time * multiplier
}
func * (multiplier: Float, time: CMTime) -> CMTime {
    return time * multiplier
}
func *= ( time: inout CMTime, multiplier: Int32) -> CMTime {
    time = time * multiplier
    return time
}
func *= ( time: inout CMTime, multiplier: Float64) -> CMTime {
    time = time * multiplier
    return time
}
func *= ( time: inout CMTime, multiplier: Float) -> CMTime {
    time = time * multiplier
    return time
}

// MARK: Divide
func / (time: CMTime, divisor: Int32) -> CMTime {
    return CMTimeMultiplyByRatio(time, 1, divisor).xd_time()
}
func /= ( time: inout CMTime, divisor: Int32) -> CMTime {
    time = time / divisor
    return time
}

// MARK: - Convenience methods
extension CMTime {
    //    func isNearlyEqualTo(time: CMTime, _ tolerance: CMTime=CMTimeMake(1,600)) -> Bool {
    //        let delta = CMTimeAbsoluteValue(self - time)
    //        return delta < tolerance
    //    }
    //    func isNearlyEqualTo(time: CMTime, _ tolerance: Float64=1.0/600) -> Bool {
    //        return isNearlyEqualTo(time, CMTime(seconds: tolerance))
    //    }
    //    func isNearlyEqualTo(time: CMTime, _ tolerance: Float=1.0/600) -> Bool {
    //        return isNearlyEqualTo(time, CMTime(seconds: tolerance))
    //    }
}

extension CMTime {
    var f: Float {
        return Float(self.f64)
    }
    var f64: Float64 {
        return CMTimeGetSeconds(self)
    }
}

func == (time: CMTime, seconds: Float64) -> Bool {
    return time == CMTime(seconds: seconds)
}
func == (time: CMTime, seconds: Float) -> Bool {
    return time == Float64(seconds)
}
func == (seconds: Float64, time: CMTime) -> Bool {
    return time == seconds
}
func == (seconds: Float, time: CMTime) -> Bool {
    return time == seconds
}
func != (time: CMTime, seconds: Float64) -> Bool {
    return !(time == seconds)
}
func != (time: CMTime, seconds: Float) -> Bool {
    return time != Float64(seconds)
}
func != (seconds: Float64, time: CMTime) -> Bool {
    return time != seconds
}
func != (seconds: Float, time: CMTime) -> Bool {
    return time != seconds
}

public func < (time: CMTime, seconds: Float64) -> Bool {
    return time < CMTime(seconds: seconds)
}
public func < (time: CMTime, seconds: Float) -> Bool {
    return time < Float64(seconds)
}
public func <= (time: CMTime, seconds: Float64) -> Bool {
    return time < seconds || time == seconds
}
public func <= (time: CMTime, seconds: Float) -> Bool {
    return time < seconds || time == seconds
}
public func < (seconds: Float64, time: CMTime) -> Bool {
    return CMTime(seconds: seconds) < time
}
public func < (seconds: Float, time: CMTime) -> Bool {
    return Float64(seconds) < time
}
public func <= (seconds: Float64, time: CMTime) -> Bool {
    return seconds < time || seconds == time
}
public func <= (seconds: Float, time: CMTime) -> Bool {
    return seconds < time || seconds == time
}

public func > (time: CMTime, seconds: Float64) -> Bool {
    return time > CMTime(seconds: seconds)
}
public func > (time: CMTime, seconds: Float) -> Bool {
    return time > Float64(seconds)
}
public func >= (time: CMTime, seconds: Float64) -> Bool {
    return time > seconds || time == seconds
}
public func >= (time: CMTime, seconds: Float) -> Bool {
    return time > seconds || time == seconds
}
public func > (seconds: Float64, time: CMTime) -> Bool {
    return CMTime(seconds: seconds) > time
}
public func > (seconds: Float, time: CMTime) -> Bool {
    return Float64(seconds) > time
}
public func >= (seconds: Float64, time: CMTime) -> Bool {
    return seconds > time || seconds == time
}
public func >= (seconds: Float, time: CMTime) -> Bool {
    return seconds > time || seconds == time
}

// MARK: - Debugging
extension CMTime: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "\(CMTimeGetSeconds(self))"
    }
    public var debugDescription: String {
        return String(describing: CMTimeCopyDescription(nil, self))
    }
}
