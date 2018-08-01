//
//  ExportViewController.swift
//  VideoCat
//
//  Created by Vito on 2018/7/18.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices
import MBProgressHUD
import VFCabbage

class ExportViewController: UIViewController {

    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var thumbPreviewCollectionView: UICollectionView!
    @IBOutlet weak var currentPreviewImageView: UIImageView!
    
    var context: EditContext!
    private var imageGenerator: AVAssetImageGenerator!
    private var exportSession: AVAssetExportSession?
    
    fileprivate var images: [UIImage] = []
    
    deinit {
        imageGenerator.cancelAllCGImageGeneration()
        exportSession?.cancelExport()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.context = editContext
        thumbPreviewCollectionView.isUserInteractionEnabled = false
        thumbPreviewCollectionView.dataSource = self
        
        let timeline = context.viewModel.buildTimeline()
        let compositionGenerator = CompositionGenerator(timeline: timeline)
        compositionGenerator.renderSize = context.viewModel.renderSize
        
        imageGenerator = compositionGenerator.buildImageGenerator()
        exportSession = compositionGenerator.buildExportSession(presetName: AVAssetExportPresetMediumQuality)
        
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = context.viewModel.renderSize
        let times: [NSValue] = {
            var times: [NSValue] = []
            let duration = imageGenerator.asset.duration.seconds
            let count = ceil((UIScreen.main.bounds.width - 32) / 44)
            for i in 0..<Int(count) {
                let time = CMTime.init(value: Int64(Double(i) / Double(count) * duration * 600), 600)
                times.append(NSValue.init(time: time))
            }
            return times
        }()
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { [weak self] (time, image, actualTime, result, error) in
            guard let strongSelf = self else { return }
            if let image = image {
                strongSelf.images.append(UIImage(cgImage: image))
                DispatchQueue.main.async {
                    if strongSelf.images.count == 1 {
                        strongSelf.currentPreviewImageView.image = strongSelf.images.first
                        strongSelf.thumbImageView.image = strongSelf.images.first
                    }
                    strongSelf.thumbPreviewCollectionView.reloadData()
                }
            } else {
                print("load thumb image failed")
            }
        }
        
        let panGesture = UIPanGestureRecognizer.init()
        currentPreviewImageView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(panPreviewImageViewAction(_:)))
        
    }
    
    var offset: CGFloat = 0
    @objc func panPreviewImageViewAction(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            panGesture.setTranslation(.zero, in: panGesture.view)
        }
        let translation = panGesture.translation(in: panGesture.view)
        offset += translation.x
        
        panGesture.setTranslation(.zero, in: panGesture.view)
        offset = min(max(0, offset), thumbPreviewCollectionView.frame.size.width - currentPreviewImageView.frame.size.width)
        currentPreviewImageView.transform = CGAffineTransform.init(translationX: offset, y: 0)
        updatePreviewImageIfNeed()
    }
    
    var previewIndex: Int = 0
    func updatePreviewImageIfNeed() {
        let index = Int(ceil((offset + 44) / 44)) - 1
        if index == previewIndex {
            return
        }
        previewIndex = index
        let image = images[previewIndex]
        currentPreviewImageView.image = image
        thumbImageView.image = image
    }

    @IBAction func exportAction(_ sender: Any) {
        MBProgressHUD.showLoading(inView: self.view)
        exportSession?.exportAsynchronously(completionHandler: { [weak exportSession, weak self] in
            guard let strongSelf = self, let exportSession = exportSession else {
                return
            }
            if let error = exportSession.error {
                DispatchQueue.main.async {
                    MBProgressHUD.showError(title: error.localizedDescription)
                }
                return
            }
            if let url = exportSession.outputURL {
                DispatchQueue.main.async {
                    MBProgressHUD.dismiss(inView: strongSelf.view, animated: true)
                    strongSelf.saveFileToPhotos(fileURL: url)
                }
            }
        })
    }
    
    private func saveFileToPhotos(fileURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { [weak self] (saved, error) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                if saved {
                    let alertController = UIAlertController(title: "😀 Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    strongSelf.present(alertController, animated: true, completion: nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? ""
                    let alertController = UIAlertController(title: "😢 Video can't save to Photos.app, error: \(errorMessage)", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    strongSelf.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
}

extension ExportViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbCell", for: indexPath)
        if let cell = cell as? ThumbCell {
            cell.imageView.image = images[indexPath.item]
        }
        
        return cell
    }
}

class ThumbCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
}
