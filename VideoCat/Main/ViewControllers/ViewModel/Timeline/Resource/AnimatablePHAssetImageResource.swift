//
//  AnimatablePHAssetImageResource.swift
//  VideoCat
//
//  Created by Vito on 2018/7/25.
//  Copyright © 2018 Vito. All rights reserved.
//

import AVFoundation
import Photos
import CoreImage

class AnimatablePHAssetImageResource: PHAssetImageResource {
    open override func image(at time: CMTime, renderSize: CGSize) -> CIImage? {
        guard let image = self.image else {
            return nil
        }
        let fillTransform = CGAffineTransform.transform(by: image.extent, aspectFillRect: CGRect(origin: .zero, size: renderSize))
        let offset = (time.seconds / selectedTimeRange.duration.seconds) * 30
        let offsetTransform = CGAffineTransform(translationX: CGFloat(offset), y: CGFloat(offset / 2))
        let scaleTransform = CGAffineTransform(scaleX: 2, y: 2)
        return image.transformed(by: fillTransform.concatenating(offsetTransform).concatenating(scaleTransform))
    }
}
