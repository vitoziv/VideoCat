//
//  AssetCell.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import Photos

class AssetCell: UICollectionViewCell {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var bottomBackgroundImageView: UIImageView!
    @IBOutlet weak var timeLabel: UILabel!
    
    private var requestID: PHImageRequestID?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
    }
    
    func configure(asset: PHAsset) {
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        let options = PHImageRequestOptions()
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        requestID = PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFit, options: options) { [weak self] (image, info) in
            guard let strongSelf = self else { return }
            strongSelf.coverImageView.image = image
        }
        
        timeLabel.text = String.videoTimeString(from: asset.duration)
    }

}
