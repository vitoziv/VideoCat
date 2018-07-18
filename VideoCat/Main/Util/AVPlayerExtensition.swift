//
//  AVPlayerExtensition.swift
//  VideoCat
//
//  Created by Vito on 2018/7/18.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation

extension AVPlayer {
    func reloadFrame() {
        guard rate == 0 else { return }
        guard let item = currentItem else { return }
        let videoComposition = item.videoComposition?.mutableCopy() as? AVVideoComposition
        item.videoComposition = videoComposition
    }
}
