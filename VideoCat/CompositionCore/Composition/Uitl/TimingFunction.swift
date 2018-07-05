//
//  TimingFunction.swift
//  VideoCat
//
//  Created by Vito on 2018/7/5.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

public class TimingFunction {
    public class Quart {
        
        public static func  easeIn(t: Float, b: Float, c: Float, d: Float) -> Float {
            let t = t / d
            return c*t*t*t*t + b
        }
        
        public static func  easeOut(t: Float, b: Float, c: Float, d: Float) -> Float {
            let t = t/d-1
            return -c * (t*t*t*t - 1) + b
        }
        
        public static func  easeInOut(t: Float, b: Float, c: Float, d: Float) -> Float {
            var t = t / (d / 2)
            if (t < 1) {
                return c/2*t*t*t*t + b;
            }
            t = t - 2
            return -c/2 * (t*t*t*t - 2) + b;
        }
        
    }
}


