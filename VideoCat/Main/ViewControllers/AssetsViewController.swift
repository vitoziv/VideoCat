//
//  AssetsViewController.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "AssetCell"

protocol AssetsViewControllerDelegate: class {
    func assetsViewControllerDidCancel(_ viewController: AssetsViewController)
    func assetsViewController(_ viewController: AssetsViewController, didPicked asset: PHAsset)
}

class AssetsViewController: UICollectionViewController {

    weak var delegate: AssetsViewControllerDelegate?
    fileprivate(set) var viewModel = AssetsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let cellNumberPerLine: CGFloat = 4
            let width = floor((UIScreen.main.bounds.width - (cellNumberPerLine * layout.minimumInteritemSpacing)) / cellNumberPerLine)
            layout.itemSize = CGSize(width: width, height: width)
        }
        
        viewModel.requestLibraryPermission { [weak self] (status) in
            guard let strongSelf = self else { return }
            if status == .authorized {
                strongSelf.viewModel.loadAssets()
                strongSelf.collectionView?.reloadData()
            } else {
                
                switch status {
                case .denied:
                        let alert = UIAlertController(title: nil, message: NSLocalizedString("Access photolibrary is denied.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                            strongSelf.dismiss(animated: true, completion: nil)
                        })
                        alert.addAction(action)
                        strongSelf.present(alert, animated: true, completion: nil)
                case .restricted:
                        let alert = UIAlertController(title: nil, message: NSLocalizedString("Access photolibrary is restricted.", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: { (action) in
                            strongSelf.dismiss(animated: true, completion: nil)
                        })
                        alert.addAction(action)
                        strongSelf.present(alert, animated: true, completion: nil)
                default:
                    break
                }
                
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        delegate?.assetsViewControllerDidCancel(self)
    }
    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.assets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        let asset = viewModel.assets.object(at: indexPath.item)
        
        // Configure the cell
        if let cell = cell as? AssetCell {
            cell.configure(asset: asset)
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = viewModel.assets.object(at: indexPath.item)
        delegate?.assetsViewController(self, didPicked: asset)
    }
    
}
