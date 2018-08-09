//
//  VIPlayerView.swift
//  VIPlayer
//
//  Created by Vito on 25/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

public class VIPlayerView: UIView {

    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    public var player: AVPlayer? {
        get {
            return (layer as? AVPlayerLayer)?.player
        }
        set {
            (layer as? AVPlayerLayer)?.player = newValue
        }
    }

}
