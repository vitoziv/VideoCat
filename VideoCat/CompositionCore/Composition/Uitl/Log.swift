//
//  Log.swift
//  VideoCat
//
//  Created by Vito on 2018/6/24.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import os

private let subsystem = "com.vito.videocat"

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
    
    static let infoLog = OSLog(subsystem: subsystem, category: "INFO")
    static func info(_ string: String) {
        #if DEBUG
        if output.contains(.info) {
            print("<INFO>: %@", string)
            os_log("<INFO>: %@", log: infoLog, type: .info, string)
        }
        #endif
    }
    
    static let debugLog = OSLog(subsystem: subsystem, category: "DEBUG")
    static func debug(_ string: String) {
        #if DEBUG
        if output.contains(.debug) {
            print("<DEBUG>: %@", string)
            os_log("<DEBUG>: %@", log: debugLog, type: .debug, string)
        }
        #endif
    }
    
    static let warningLog = OSLog(subsystem: subsystem, category: "WARNING")
    static func warning(_ string: String) {
        if output.contains(.warning) {
            print("<WARNING>: %@", string)
            os_log("<WARNING>: %@", log: warningLog, type: .fault, string)
        }
    }
    
    static let errorLog = OSLog(subsystem: subsystem, category: "ERROR")
    static func error(_ string: String) {
        if output.contains(.error) {
            print("<ERROR>: %@", string)
            os_log("<ERROR>: %@", log: errorLog, type: .error, string)
        }
    }
}
