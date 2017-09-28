//
//  AssetsViewModel.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation
import Photos

class AssetsViewModel {
    var assets: PHFetchResult<PHAsset> = PHFetchResult()
    
    func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(keyPath: \PHAsset.creationDate, ascending: false)]
        assets = PHAsset.fetchAssets(with: .video, options: options)
    }
}
