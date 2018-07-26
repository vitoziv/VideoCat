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
    
    @available(iOS 10.0, *)
    static let infoLog = OSLog(subsystem: subsystem, category: "INFO")
    
    static func info(_ string: String) {
        #if DEBUG
        if output.contains(.info) {
            if #available(iOS 10.0, *) {
                os_log("<INFO>: %@", log: infoLog, type: .info, string)
            } else {
                print("<INFO>: %@", string)
            }
        }
        #endif
    }
    
    @available(iOS 10.0, *)
    static let debugLog = OSLog(subsystem: subsystem, category: "DEBUG")
    
    static func debug(_ string: String) {
        #if DEBUG
        if output.contains(.debug) {
            if #available(iOS 10.0, *) {
                os_log("<DEBUG>: %@", log: debugLog, type: .debug, string)
            } else {
                print("<DEBUG>: %@", string)
            }
        }
        #endif
    }
    
    @available(iOS 10.0, *)
    static let warningLog = OSLog(subsystem: subsystem, category: "WARNING")
    static func warning(_ string: String) {
        if output.contains(.warning) {
            if #available(iOS 10.0, *) {
                os_log("<WARNING>: %@", log: warningLog, type: .fault, string)
            } else {
                print("<WARNING>: %@", string)
            }
        }
    }
    
    @available(iOS 10.0, *)
    static let errorLog = OSLog(subsystem: subsystem, category: "ERROR")
    static func error(_ string: String) {
        if output.contains(.error) {
            if #available(iOS 10.0, *) {
                os_log("<ERROR>: %@", log: errorLog, type: .error, string)
            } else {
                print("<ERROR>: %@", string)
            }
        }
    }
}
