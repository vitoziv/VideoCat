//
//  FilterItemProvider.swift
//  VideoCat
//
//  Created by Vito on 2018/7/13.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit

class FilterItemProvider: ItemsProvider {
    
    var items: [EditItem] = []
    let context = editContext
    
    
    
    init() {
        let lutNoneInfo = EditInfo()
        lutNoneInfo.cellIdentifier = BasicEditItemCell.reuseIdentifier
        lutNoneInfo.title = "none"
        let lutNonefilterItem = EditItem(info: lutNoneInfo) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.context?.viewModel.trackItems.forEach({ (trackItem) in
                trackItem.configuration.videoConfiguration.filterProcessor = nil
            })
            strongSelf.context?.videoView.player.player.reloadFrame()
        }
        items.append(lutNonefilterItem)
        
        let lutFilters = [("1977", Bundle.main.path(forResource: "lut_1977", ofType: "png")),
                          ("aden", Bundle.main.path(forResource: "lut_aden", ofType: "png")),
                          ("bmdfilm", Bundle.main.path(forResource: "lut_bmdfilm", ofType: "png"))]
        
        lutFilters.forEach { (info) in
            if let imagePath = info.1 {
                if let image = UIImage.init(contentsOfFile: imagePath) {
                    let lutItem = lutEditItem(with: info.0, image: image)
                    items.append(lutItem)
                }
            }
        }
        // TODO: 实现自定义调试亮度、曝光、白平衡 等滤镜
    }
    
    private func lutEditItem(with name: String, image: UIImage) -> EditItem {
        let lutInfo = EditInfo()
        lutInfo.cellIdentifier = BasicEditItemCell.reuseIdentifier
        lutInfo.title = name
        let lutfilterItem = EditItem(info: lutInfo) { [weak self] in
            guard let strongSelf = self else { return }
            let converter = LUTDataConverter.init(image: image)
            converter.intensity = 0.5
            strongSelf.context?.viewModel.trackItems.forEach({ (trackItem) in
                trackItem.configuration.videoConfiguration.filterProcessor = { (image) in
                    if let filter = converter.filter() {
                        filter.setValue(image, forKey: kCIInputImageKey)
                        if let outputImage = filter.outputImage {
                            return outputImage
                        }
                    }
                    
                    return image
                }
            })
            strongSelf.context?.videoView.player.player.reloadFrame()
        }
        
        return lutfilterItem
    }
    
}
