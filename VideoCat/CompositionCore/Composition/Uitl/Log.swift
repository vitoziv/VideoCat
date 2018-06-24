//
//  Log.swift
//  VideoCat
//
//  Created by Vito on 2018/6/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation

class Log {
    
    struct Output: OptionSet {
        let rawValue: Int
        
        static let info = Output(rawValue: 1 << 0)
        static let debug = Output(rawValue: 1 << 1)
        static let warning = Output(rawValue: 1 << 2)
        static let error = Output(rawValue: 1 << 3)
        
        static let all: Output = [.info, .debug, .warning, .error]
    }
    
    static var output: Output = .all
    
    static func info(_ string: String) {
        #if DEBUG
        if output.contains(.info) {
            print("<INFO>: \(string)")
        }
        #endif
    }
    
    static func debug(_ string: String) {
        #if DEBUG
        if output.contains(.debug) {
            print("<DEBUG>: \(string)")
        }
        #endif
    }
    
    static func warning(_ string: String) {
        #if DEBUG
        if output.contains(.warning) {
            print("<WARNING>: \(string)")
        }
        #endif
    }
    
    static func error(_ string: String) {
        #if DEBUG
        if output.contains(.error) {
            print("<ERROR>: \(string)")
        }
        #endif
    }
}
