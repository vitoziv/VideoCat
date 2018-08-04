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
import VFCabbage

class PassingThroughEditItemProvider: ItemsProvider {
    var items: [EditItem] = []
    let context = editContext
    
    init() {
        let addInfo = EditInfo()
        addInfo.title = "Add"
        addInfo.cellIdentifier = BasicEditItemCell.reuseIdentifier
        let addItem = EditItem(info: addInfo) {
            let actionSheet = UIAlertController.init(title: "Add resource", message: nil, preferredStyle: .actionSheet)
            let videoAction = UIAlertAction.init(title: "Video", style: .default, handler: { (action) in
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let assetsNavigationController = storyboard.instantiateViewController(withIdentifier: "AssetsNavigationController")
                if let assetsNavigationController = assetsNavigationController as? UINavigationController,
                    let assetViewController = assetsNavigationController.viewControllers.first as? AssetsViewController {
                    assetViewController.delegate = self
                    UIViewController.topMost?.present(assetsNavigationController, animated: true, completion: nil)
                }
            })
            actionSheet.addAction(videoAction)
            
            let photoAction = UIAlertAction.init(title: "Photo", style: .default, handler: { (action) in
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let assetsNavigationController = storyboard.instantiateViewController(withIdentifier: "AssetsNavigationController")
                if let assetsNavigationController = assetsNavigationController as? UINavigationController,
                    let assetViewController = assetsNavigationController.viewControllers.first as? AssetsViewController {
                    assetViewController.delegate = self
                    assetViewController.viewModel.type = .image
                    UIViewController.topMost?.present(assetsNavigationController, animated: true, completion: nil)
                }
            })
            actionSheet.addAction(photoAction)
            
            let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancelAction)
            
            UIViewController.topMost?.present(actionSheet, animated: true, completion: nil)
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
        if viewController.viewModel.type == .video {
            let resource = PHAssetTrackResource(phasset: asset)
            MBProgressHUD.showLoading()
            resource.prepare { [weak self] (status, error) in
                if status == .avaliable {
                    MBProgressHUD.dismiss()
                    resource.selectedTimeRange = CMTimeRange.init(start: kCMTimeZero, duration: resource.duration)
                    self?.finishAddResource(resource)
                } else {
                    MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
                }
            }
        } else {
            let resource = AnimatablePHAssetImageResource(asset: asset)
            MBProgressHUD.showLoading()
            resource.prepare { [weak self] (status, error) in
                if status == .avaliable {
                    MBProgressHUD.dismiss()
                    resource.selectedTimeRange = CMTimeRange(start: kCMTimeZero, duration: CMTime.init(value: 3000, 600))
                    self?.finishAddResource(resource)
                } else {
                    MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
                }
            }
        }
        
    }
    
    private func finishAddResource(_ resource: Resource) {
        guard let context = self.context else {return}
        let index = context.timelineView.nextRangeViewIndex
        let trackItem = TrackItem(resource: resource)
        let transition = CrossDissolveTransition()
        transition.duration = CMTime(value: 900, timescale: 600)
        trackItem.videoTransition = transition
        let audioTransition = FadeInOutAudioTransition(duration: CMTime(value: 66150, timescale: 44100))
        trackItem.audioTransition = audioTransition
        if resource.isKind(of: ImageResource.self) {
            trackItem.configuration.videoConfiguration.baseContentMode = .custom
        } else {
            trackItem.configuration.videoConfiguration.baseContentMode = .aspectFill
        }
        context.viewModel.insertTrackItem(trackItem, at: index)
        context.videoView.player.replaceCurrentItem(context.viewModel.playerItem)
        context.timelineView.reload(with: context.viewModel.trackItems)
    }
}
