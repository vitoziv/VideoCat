//
//  ClipCell.swift
//  VideoCat
//
//  Created by Vito on 28/10/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class ClipCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    func configure(trackItem: TrackItem) {
        DispatchQueue.global().async { [weak self] in
            if let image = trackItem.resource.requestThumbImage() {
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    strongSelf.imageView.image = image
                }
            }
        }
        
        infoLabel.text = {
            var text = ""
            
            let seconds = trackItem.resource.trackAsset?.duration.seconds ?? 0
            text += "Video Time: \(seconds)s\n"
            
            let choosedRange = trackItem.configuration.timeRange
            text += "TimeRange: {start: \(choosedRange.start.seconds), duration: \(choosedRange.duration.seconds)}"
            
            return text
        }()
    }
    
}
