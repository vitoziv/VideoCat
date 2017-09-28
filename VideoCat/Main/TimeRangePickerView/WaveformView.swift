//
//  WaveformView.swift
//  VideoCat
//
//  Created by Vito on 27/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class WaveformView: UIView {

    override open class var layerClass: Swift.AnyClass {
        return CAShapeLayer.self
    }

    func updateBuffer(_ buffer: [Float], bufferSize: Int) {
        
    }
    
}


