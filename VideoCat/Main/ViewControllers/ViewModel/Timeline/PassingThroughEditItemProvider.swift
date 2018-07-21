//
//  PassingThroughEditItemProvider.swift
//  VideoCat
//
//  Created by Vito on 2018/7/12.
//  Copyright © 2018 Vito. All rights reserved.
//

import Foundation
import Photos
import MBProgressHUD

class PassingThroughEditItemProvider: ItemsProvider {
    var items: [EditItem] = []
    let context = editContext
    
    init() {
        let addInfo = EditInfo()
        addInfo.title = "Add"
        addInfo.cellIdentifier = BasicEditItemCell.reuseIdentifier
        let addItem = EditItem(info: addInfo) {
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let assetsNavigationController = storyboard.instantiateViewController(withIdentifier: "AssetsNavigationController")
            if let assetsNavigationController = assetsNavigationController as? UINavigationController,
                let assetViewController = assetsNavigationController.viewControllers.first as? AssetsViewController {
                assetViewController.delegate = self
                UIViewController.topMost?.present(assetsNavigationController, animated: true, completion: nil)
            }
        }
        items.append(addItem)
        
        let filterInfo = EditInfo()
        filterInfo.cellIdentifier = BasicEditItemCell.reuseIdentifier
        filterInfo.title = "filter"
        let filterItem = EditItem(info: filterInfo) { [weak self] in
            guard let strongSelf = self else { return }
            let toolView = EditToolView(frame: .zero)
            toolView.backHandler = { [weak toolView] in
                guard let toolView = toolView else { return }
                toolView.dismiss(animated: true)
            }
            toolView.itemsProvider = FilterItemProvider()
            strongSelf.context?.editToolView.present(toolView, animated: true)
        }
        items.append(filterItem)
    }
    
}

extension PassingThroughEditItemProvider: AssetsViewControllerDelegate {
    func assetsViewControllerDidCancel(_ viewController: AssetsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func assetsViewController(_ viewController: AssetsViewController, didPicked asset: PHAsset) {
        viewController.dismiss(animated: true, completion: nil)
        
        let resource = TrackVideoAssetResource(asset: asset)
        MBProgressHUD.showLoading()
        resource.loadMedia { [weak self] (status) in
            guard let context = self?.context else {return}
            if status == .avaliable {
                MBProgressHUD.dismiss()
                
                let index = context.timelineView.nextRangeViewIndex
                
                let trackItem = TrackItem(resource: resource)
                let transition = CrossDissolveTransition()
                transition.duration = CMTime(value: 3, timescale: 2)
                trackItem.videoTransition = transition
                let audioTransition = FadeInOutAudioTransition(duration: transition.duration)
                trackItem.audioTransition = audioTransition
                trackItem.resource.timeRange = CMTimeRangeMake(kCMTimeZero, resource.trackAsset!.duration)
                let audioTapHolder = AudioProcessingTapHolder()
                trackItem.configuration.audioConfiguration.audioTapHolder = audioTapHolder
                context.viewModel.insertTrackItem(trackItem, at: index)
                context.videoView.player.replaceCurrentItem(context.viewModel.playerItem)
                
                context.timelineView.appendVideoRangeView(configuration: { (rangeView) in
                    
                    // TODO: 1.完善 resource。 2.支持单个 trackItem 创建 image generator
                    
//                    let contentView = VideoRangeContentView()
//                    if resource.type == .photo {
//                        contentView.supportUnlimitTime = true
//                    }
//                    let timeRange = trackItem.configuration.timelineTimeRange
//                    let imageGenerator = clip.clipFullRangeImageGenerator(size: CGSize(width: 60, height: 60))
//                    contentView.loadImageQueue = loadImageQueue
//                    contentView.imageGenerator = imageGenerator
//                    contentView.startTime = timeRange.start
//                    contentView.endTime = timeRange.end
//                    
//                    if index > 0 {
//                        let previousClip = clips[index - 1]
//                        if let transitionDuration = previousClip.videoTransition?.duration {
//                            contentView.leftInsetDuration = transitionDuration / 2
//                        }
//                    }
//                    if let transitionDuration = trackItem.videoTransition?.duration {
//                        contentView.rightInsetDuration = transitionDuration / 2
//                    }
//                    
//                    rangeView.loadContentView(contentView)
//                    
//                    rangeView.reloadUI()
                }, at: index)
            } else {
                MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
            }
        }
    }
}
