//
//  VideoTimelineView.swift
//  VideoCat
//
//  Created by Vito on 10/10/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class VideoTimelineView: UIView {
    
    private(set) var viewModel = VideoTimelineViewModel()

    var collectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInt()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInt()
    }
    
    private func commonInt() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = viewModel.imageSize
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.clear
        addSubview(collectionView)
        
        collectionView.dataSource = self
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.register(VideoTimeLineCell.self, forCellWithReuseIdentifier: VideoTimeLineCell.reuseIdentifier)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    func configure(with url: URL, completion: (() -> Void)? = nil) {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = viewModel.imageSize
            collectionView.collectionViewLayout = layout
        }
        
        viewModel.configure(with: url)
        viewModel.prepareAsset { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.collectionView.reloadData()
            completion?()
        }
    }

}

extension VideoTimelineView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.imageCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoTimeLineCell.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? VideoTimeLineCell {
            viewModel.loadImage(at: indexPath.item, completion: { (index, image) in
                if index == indexPath.item {
                    cell.imageView.image = image
                }
            })
        }
        
        return cell
    }
}

private class VideoTimeLineCell: UICollectionViewCell {
    
    static var reuseIdentifier: String {
        return "VideoTimeLineCell"
    }
    
    var imageView: UIImageView!
    private var blackLine: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        imageView = UIImageView()
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        blackLine = UIView()
        contentView.addSubview(blackLine)
        blackLine.backgroundColor = UIColor.black
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        blackLine.translatesAutoresizingMaskIntoConstraints = false
        blackLine.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        blackLine.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        blackLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        blackLine.widthAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
}

class VideoTimelineViewModel {

    private(set) var imageCount: Int = 0
    private var cachedImages: [Int: UIImage] = [:]
    
    private(set) var actualWidthPerSecond: CGFloat = 0
    var minWidthPerSecond: CGFloat = 5
    /// TimeLine Min width
    var minWidth: CGFloat = 100
    var imageSize = CGSize(width: 100, height: 100) {
        didSet {
            imageGenerator?.maximumSize = CGSize(width: imageSize.width * 2, height: imageSize.height * 2)
        }
    }
    
    private(set) var url: URL?
    private var asset: AVAsset?
    private var imageGenerator: AVAssetImageGenerator?
    
    func configure(with url: URL) {
        self.url = url
        let asset = AVAsset(url: url)
        self.asset = asset
        imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator?.maximumSize = {
            if let track = asset.tracks(withMediaType: .video).first {
                if track.naturalSize.width / imageSize.width > track.naturalSize.height / imageSize.height {
                    return CGSize(width: 0, height: imageSize.height * 2)
                }
                return CGSize(width: imageSize.width * 2, height: 0)
            }
            return CGSize(width: imageSize.width * 2, height: imageSize.height * 2)
        }()
        imageGenerator?.apertureMode = AVAssetImageGeneratorApertureMode.productionAperture
        imageGenerator?.appliesPreferredTrackTransform = true
    }
    
    func prepareAsset(completion: @escaping () -> Void) {
        guard let asset = asset else {
            completion()
            return
        }
        asset.loadValuesAsynchronously(forKeys: ["duration"], completionHandler: { [weak self] in
            guard let strongSelf = self else { return }
            let duration = asset.duration.seconds
            
            let actualWidthPerSecond: CGFloat
            // if fill the timeline view don't have enough time, per point respresent less time
            if CGFloat(duration) * strongSelf.minWidthPerSecond < strongSelf.minWidth {
                actualWidthPerSecond = strongSelf.minWidth / CGFloat(duration)
            } else {
                actualWidthPerSecond = strongSelf.minWidthPerSecond
            }
            
            let secondPerImage = strongSelf.imageSize.width / actualWidthPerSecond
            strongSelf.imageCount = Int(ceil(CGFloat(duration) / secondPerImage))
            
            // Real widthPerSecond is calculated based on real contentSize's width
            strongSelf.actualWidthPerSecond = CGFloat(strongSelf.imageCount) * strongSelf.imageSize.width / CGFloat(duration)
            
            DispatchQueue.main.async {
                completion()
            }
        })
    }
    
    func loadImage(at index: Int, completion: @escaping (Int, UIImage) -> Void) {
        guard let asset = asset, let imageGenerator = imageGenerator else {
            completion(index, UIImage())
            return
        }
        
        if let image = cachedImages[index] {
            completion(index, image)
            return
        }
        
        DispatchQueue.global().async {
            let secondPerImage = self.imageSize.width / self.actualWidthPerSecond
            let seconds = CGFloat(index) * secondPerImage
            let time = CMTime(seconds: Double(seconds), preferredTimescale: asset.duration.timescale)
            
            let resultImage: UIImage
            if let image = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                resultImage = UIImage(cgImage: image)
            } else {
                resultImage = UIImage()
            }
            self.cachedImages[index] = resultImage
            self.checkCachedImage(currentCacheIndex: index)
            DispatchQueue.main.async {
                completion(index, resultImage)
            }
        }
        
    }
    
    private func checkCachedImage(currentCacheIndex: Int) {
        if cachedImages.count < 40 {
            return
        }
        
        let minIndex = max(0, currentCacheIndex - 10)
        let maxIndex = currentCacheIndex + 10
        
        let validIndex = minIndex...maxIndex
        cachedImages.keys.forEach { (index) in
            if !validIndex.contains(index) {
                cachedImages.removeValue(forKey: index)
            }
        }
        
    }
}
