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

class PanelViewController: UIViewController {
    
    @IBOutlet weak var timelineCollectionView: UICollectionView!
    private let viewModel = PanelViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? UINavigationController,
            let assetViewController = viewController.viewControllers.first as? AssetsViewController {
            assetViewController.delegate = self
        }
    }
    
    @IBAction func debugAction(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Demo", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "PlayerTestViewController")
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension PanelViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.panel.trackItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipCell", for: indexPath)
        let item = viewModel.panel.trackItems[indexPath.item]
        if let cell = cell as? ClipCell {
            cell.configure(trackItem: item)
        }
        
        return cell
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
                let trackItem = TrackItem(resource: resource)
                let duration = resource.trackAsset!.duration
                trackItem.configuration.timeRange = CMTimeRangeMake(kCMTimeZero, duration)
                strongSelf.viewModel.panel.trackItems.append(trackItem)
                strongSelf.timelineCollectionView.reloadData()
            } else {
                MBProgressHUD.showError(title: NSLocalizedString("Can't use this video", comment: ""))
            }
        }
    }
    
}

