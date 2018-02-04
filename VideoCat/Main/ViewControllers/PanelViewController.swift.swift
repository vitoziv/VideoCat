//
//  PanelViewController.swift
//  VideoCat
//
//  Created by Vito on 27/08/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import Photos
import MBProgressHUD
import RxCocoa

class PanelViewController: UIViewController {
    
    @IBOutlet weak var timeLineView: TimeLineView!
    @IBOutlet weak var videoView: VideoView!
    private let viewModel = TimelineViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let inset = UIScreen.main.bounds.width / 2 - 24
        timeLineView.scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        bindAction()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? UINavigationController,
            let assetViewController = viewController.viewControllers.first as? AssetsViewController {
            assetViewController.delegate = self
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        timeLineView.resignVideoRangeView()
    }
    
    @IBAction func debugAction(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Demo", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PlayerTestViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Helper
    fileprivate var timeObserver: Any?
    fileprivate func bindAction() {
        timeObserver = videoView.player.player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            strongSelf.playerTimeDidChanged(time: time)
        })
        _ = timeLineView.scrollView.rx.observeWeakly(CGPoint.self, "contentOffset").takeUntil(rx.deallocated).subscribe(onNext: { [weak self] (offset) in
            guard let strongSelf = self else { return }
            guard let offset = offset else { return }
            let time = strongSelf.timeLineView.getTime(at: offset.x)
            strongSelf.videoView.player.player.fl_seekSmoothly(to: time.0)
        })
    }
    
    fileprivate func playerTimeDidChanged(time: CMTime) {
        timeLineView.adjustCollectionViewOffset(time: time)
    }
    
}

extension PanelViewController: AssetsViewControllerDelegate {
    func assetsViewControllerDidCancel(_ viewController: AssetsViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func assetsViewController(_ viewController: AssetsViewController, didPicked asset: PHAsset) {
        viewController.dismiss(animated: true, completion: nil)
        
        let resource = TrackVideoAssetResource(asset: asset)
        MBProgressHUD.showLoading()
        resource.loadMedia { [weak self] (status) in
            guard let strongSelf = self else { return }
            if status == .avaliable {
                MBProgressHUD.dismiss()
                let index = strongSelf.timeLineView.nextRangeViewIndex
                strongSelf.timeLineView.append(asset: resource.trackAsset!, at: index)
                
                let trackItem = TrackItem(resource: resource)
                trackItem.configuration.timeRange = CMTimeRangeMake(kCMTimeZero, resource.trackAsset!.duration)
                strongSelf.viewModel.insertTrackItem(trackItem, at: index)
                strongSelf.videoView.player.replaceCurrentItem(strongSelf.viewModel.playerItem)
            } else {
                MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
            }
        }
    }
    
}

