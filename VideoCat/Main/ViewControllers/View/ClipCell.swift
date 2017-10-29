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
            let seconds = trackItem.resource.trackAsset?.duration.seconds ?? 0
            let choosedRange = trackItem.configuration.timeRange
            
            return """
            Video Time: \(seconds.format(f: ".2"))s
            TimeRange: {start: \(choosedRange.start.seconds.format(f: ".2")), duration: \(choosedRange.duration.seconds.format(f: ".2"))}
            """
        }()
    }
    
}

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
