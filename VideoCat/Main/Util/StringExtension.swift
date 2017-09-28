//
//  StringExtension.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation

private let videoTimeFormatter = { () -> DateComponentsFormatter in
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.pad]
    return formatter
}()

extension String {
    static func videoTimeString(from seconds: TimeInterval) -> String {
        return videoTimeFormatter.string(from: seconds) ?? "0"
    }
}
