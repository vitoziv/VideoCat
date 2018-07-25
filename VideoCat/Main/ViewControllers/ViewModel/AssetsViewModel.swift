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
    var type: PHAssetMediaType = .video
    
    func requestLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    completion(status)
                }
            })
        } else {
            completion(status)
        }
    }
    
    func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(keyPath: \PHAsset.creationDate, ascending: false)]
        assets = PHAsset.fetchAssets(with: type, options: options)
    }
}
