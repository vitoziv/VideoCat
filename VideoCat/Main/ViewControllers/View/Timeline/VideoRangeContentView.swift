//
//  VideoRangeContentView.swift
//  VideoCat
//
//  Created by Vito on 24/12/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import VFCabbage

class VideoRangeContentView: RangeContentView {
    
    var loadImageQueue: DispatchQueue?
    var workitems: [Int: DispatchWorkItem] = [:]
    var imageGenerator: AVAssetImageGenerator? {
        didSet {
            updateDataIfNeed()
        }
    }
    
    private var imageViews: [Int: AssetThumbImageView] = [:]
    private var reuseableImageViews: [AssetThumbImageView] = []
    
    override var maxDuration: CMTime {
        get {
            guard let asset = imageGenerator?.asset else {
                return kCMTimeIndefinite
            }
            return asset.duration
        }
        set {}
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        imageGenerator?.cancelAllCGImageGeneration()
    }
    
    private func commonInit() {
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        timeDidChange()
        updateDataIfNeed()
    }
    
    override func reloadData() {
        super.reloadData()
        let indexRange = visiableRange()
        guard indexRange.count > 0 else {
            return
        }
        removeImageViewsOutOf(range: indexRange)
        indexRange.forEach { (index) in
            loadImageView(for: index)
        }
    }
    
    override func updateDataIfNeed() {
        super.updateDataIfNeed()
        let indexRange = visiableRange()
        guard indexRange.count > 0 else {
            return
        }
        removeImageViewsOutOf(range: indexRange)
        indexRange.forEach { (index) in
            loadImageView(for: index)
        }
    }
    
    override func endExpand() {
        super.endExpand()
        updateDataIfNeed()
    }
    
    // MARK: - DataSource
    
    private var imageSize: CGSize {
        return CGSize(width: bounds.height, height: bounds.height)
    }
    
    private func removeImageViewsOutOf(range: CountableRange<Int>) {
        let outIndex = imageViews.keys.filter { (index) -> Bool in
            return !range.contains(index)
        }
        outIndex.forEach { (index) in
            if let imageView = imageViews.removeValue(forKey: index) {
                imageView.tag = 0
                imageView.image = nil
                imageView.removeFromSuperview()
                reuseableImageViews.append(imageView)
            }
        }
    }
    
    private func loadImageView(for index: Int) {
        guard let imageGenerator = imageGenerator else {
            return
        }
        
        let imageView: AssetThumbImageView = {
            if let imageView = imageViews[index] {
                return imageView
            }
            
            let imageView = createImageView(at: index)
            imageViews[index] = imageView
            return imageView
        }()
        
        let preIndex = imageView.tag
        imageView.tag = index
        // Layout
        layout(imageView: imageView, at: index)
//        imageView.configureDebugIndexLabel(index: index)
        
        let secondsPerImage = Double(imageSize.width / widthPerSecond)
        let start = secondsPerImage * Double(index)
        let end = min(secondsPerImage * Double(index + 1), imageGenerator.asset.duration.seconds)
        let time = CMTime(seconds: (start + end) * 0.5, preferredTimescale: imageGenerator.asset.duration.timescale)
        if let generator = imageGenerator as? ImageGenerator, let image = generator.getCacheImage(at: time) {
            if preIndex != index {
                imageView.image = UIImage(cgImage: image)
            }
            return
        }
        imageView.image = ImagePool.current.defaultPlaceholderImage(size: CGSize(width: 200, height: 200))
        if !canLoadImageAsync {
            return
        }
        if workitems[index] != nil {
            return
        }
        // Image generetor
        let workitem = DispatchWorkItem(block: { [weak imageView, weak self] in
            defer { self?.workitems.removeValue(forKey: index) }
            guard let imageView = imageView else { return }
            var cancel = true
            DispatchQueue.main.sync {
                cancel = imageView.tag != index
            }
            guard !cancel else { return }
            imageView.configure(imageGenerator: imageGenerator, at: time)
        })
        loadImageQueue?.async(execute: workitem)
        workitems[index] = workitem
    }
    
    private func createImageView(at index: Int) -> AssetThumbImageView {
        if let imageView = reuseableImageViews.first {
            reuseableImageViews.removeFirst()
            imageView.tag = -1
            imageView.image = nil
            return imageView
        }
        let imageView = AssetThumbImageView(frame: CGRect.zero)
        imageView.tag = -1
        imageView.image = ImagePool.current.defaultPlaceholderImage(size: CGSize(width: 200, height: 200))
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    private func layout(imageView: AssetThumbImageView, at index: Int) {
        if let imageViewSuperView = imageView.superview, imageViewSuperView == self {
            for constraint in constraints {
                if let identifier = constraint.identifier, identifier == "VideoRangeContentView-AssetThumbImageView",
                    let firstItem = constraint.firstItem as? AssetThumbImageView, firstItem == imageView {
                    constraint.constant = round((CGFloat(index) * imageSize.width))
                    break
                }
            }
        } else {
            imageView.removeFromSuperview()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(imageView, at: 0)
            let imageSize = self.imageSize
            imageView.bounds = CGRect(origin: CGPoint.zero, size: imageSize)
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            let imageViewLeftConstraint = imageView.leftAnchor.constraint(equalTo: leftAnchor)
            imageViewLeftConstraint.constant = round((CGFloat(index) * imageSize.width))
            imageViewLeftConstraint.isActive = true
            imageViewLeftConstraint.identifier = "VideoRangeContentView-AssetThumbImageView"
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height).isActive = true
        }
    }
    
    // MARK: - Helper
    
    private func visiableRange() -> CountableRange<Int> {
        guard imageSize.height > 0 else {
            return 0..<0
        }
        guard let asset = imageGenerator?.asset else {
            imageViews.forEach({ (key, value) in
                value.tag = 0
                value.image = nil
                value.removeFromSuperview()
                reuseableImageViews.append(value)
            })
            imageViews.removeAll()
            return 0..<0
        }
        guard let window = UIApplication.shared.keyWindow else {
            return 0..<0
        }
        let rectInWindow = convert(bounds, to: window)
        
        let availableRectInWindow = window.bounds.intersection(rectInWindow)
        guard !availableRectInWindow.isNull else {
            return 0..<0
        }
        
        let availableRect = convert(availableRectInWindow, from: window)
        
        let startOffset = availableRect.origin.x
        var startIndexOfImage = Int(startOffset / imageSize.width)
        var endIndexOfImage = Int(ceil((availableRect.width + startOffset) / imageSize.width))
        
        if preloadCount > 0 {
            startIndexOfImage = startIndexOfImage - preloadCount
            if !supportUnlimitTime {
                startIndexOfImage = max(0, startIndexOfImage)
            }
            endIndexOfImage = endIndexOfImage + preloadCount
            if !supportUnlimitTime {
                let maxIndex = Int(ceil(CGFloat(asset.duration.seconds) * widthPerSecond / imageSize.width))
                endIndexOfImage = min(maxIndex, endIndexOfImage)
            }
        }
        startIndexOfImage = min(startIndexOfImage, endIndexOfImage)
        
        let indexRange = startIndexOfImage..<endIndexOfImage
        return indexRange
    }
    
}

class AssetThumbImageView: UIImageView {
    
    var imageGenerator: AVAssetImageGenerator?
    
    func configure(imageGenerator: AVAssetImageGenerator, at time: CMTime) {
        do {
            let cgimage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            DispatchQueue.main.async {
                self.image = UIImage(cgImage: cgimage)
            }
        } catch let e {
            Log.error("Image generator copyCGImage at time: \(time.debugDescription) error: \(e.localizedDescription)")
        }
    }
    
    var debugIndexLabel: UILabel?
    func configureDebugIndexLabel(index: Int) {
        if debugIndexLabel == nil {
            let debugIndexLabel = UILabel()
            addSubview(debugIndexLabel)
            debugIndexLabel.backgroundColor = UIColor.init(white: 0, alpha: 0.3)
            debugIndexLabel.textColor = UIColor.white
            debugIndexLabel.textAlignment = .center
            self.debugIndexLabel = debugIndexLabel
            
            debugIndexLabel.translatesAutoresizingMaskIntoConstraints = false
            debugIndexLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            debugIndexLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
            debugIndexLabel.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            debugIndexLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        debugIndexLabel?.text = "\(index)"
    }
    
}
