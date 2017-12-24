//
//  VideoRangeContentView.swift
//  VideoCat
//
//  Created by Vito on 24/12/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class VideoRangeContentView: UIView {
    
    var asset: AVAsset? {
        didSet {
            updateThumbIfNeed()
            startTime = kCMTimeZero
            endTime = kCMTimeZero
        }
    }
    /// Asset's selected timerange
    var startTime: CMTime = kCMTimeZero {
        didSet {
            timeLabel.text = String(format: "(%.1f, %.1f)", startTime.seconds, endTime.seconds - startTime.seconds)
            
            // bounds offset, let images show on the right place
            let xOffset = CGFloat(startTime.seconds) * widthPerSecond
            var offsetBounds = bounds
            offsetBounds.origin.x = xOffset
            bounds = offsetBounds
            
            timeLabel.transform = CGAffineTransform(translationX: xOffset, y: 0)
        }
    }
    var endTime: CMTime = kCMTimeZero{
        didSet {
            timeLabel.text = String(format: "(%.1f, %.1f)", startTime.seconds, endTime.seconds - startTime.seconds)
        }
    }
    
    var widthPerSecond: CGFloat = 10
    /// Preload left and right image thumb, if preloadCount is 2, then will preload 2 left image thumbs and 2 right image thumbs
    var preloadCount: Int = 2
    
    var contentWidth: CGFloat {
        let duration = endTime.seconds - startTime.seconds
        return CGFloat(duration) * widthPerSecond
    }
    
    private(set) var timeLabel: UILabel!
    private var imageViews: [Int: AssetThumbImageView] = [:]
    private var reuseableImageViews: [AssetThumbImageView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        clipsToBounds = true
        
        timeLabel = UILabel()
        timeLabel.backgroundColor = UIColor(white: 0, alpha: 0.3)
        timeLabel.font = UIFont.systemFont(ofSize: 11)
        timeLabel.textColor = UIColor.white
        addSubview(timeLabel)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        timeLabel.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateThumbIfNeed()
    }
    
    func updateThumbIfNeed() {
        guard imageSize.height > 0 else {
            return
        }
        guard let asset = asset else {
            imageViews.forEach({ (key, value) in
                value.image = nil
                value.removeFromSuperview()
                reuseableImageViews.append(value)
            })
            imageViews.removeAll()
            return
        }
        guard let window = window else {
            return
        }
        let rectInWindow = convert(bounds, to: window)
        
        let availableRectInWindow = window.bounds.intersection(rectInWindow)
        guard !availableRectInWindow.isNull else {
            return
        }
        
        let availableRect = convert(availableRectInWindow, from: window)
        
        let startOffset = availableRect.origin.x
        var startIndexOfImage = Int(startOffset / imageSize.width)
        var endIndexOfImage = Int(ceil((availableRect.width + startOffset) / imageSize.width))
        
        if preloadCount > 0 {
            startIndexOfImage = max(0, startIndexOfImage - preloadCount)
            let maxIndex = Int(ceil(CGFloat(asset.duration.seconds) * widthPerSecond / imageSize.width))
            endIndexOfImage = min(maxIndex, endIndexOfImage + preloadCount)
        }
        
        let indexRange = startIndexOfImage..<endIndexOfImage
        removeImageViewsOutOf(range: indexRange)
        indexRange.forEach { (index) in
            loadImageView(for: index)
        }
    }
    
    func expand(contentWidth: CGFloat, left: Bool) {
        let seconds = contentWidth / widthPerSecond
        if left {
            var startSeconds = max(0, startTime.seconds - Double(seconds))
            startSeconds = min(startSeconds, endTime.seconds)
            startTime = CMTime(seconds: startSeconds, preferredTimescale: 600)
        } else {
            guard let asset = asset else {
                return
            }
            let maxDuration: Double = asset.duration.seconds
            let endSeconds = max(min(endTime.seconds + Double(seconds), maxDuration), startTime.seconds)
            endTime = CMTime(seconds: endSeconds, preferredTimescale: 600)
        }
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
                imageView.image = nil
                imageView.removeFromSuperview()
                reuseableImageViews.append(imageView)
            }
        }
    }
    
    private func loadImageView(for index: Int) {
        guard let asset = asset else {
            return
        }
        if let imageView = imageViews[index] {
            updateLayoutIfNeed(imageView: imageView, at: index)
            return
        }
        
        let imageView: AssetThumbImageView = {
            if let imageView = reuseableImageViews.first {
                reuseableImageViews.removeFirst()
                imageView.tag = index
                imageView.prepareForReuse()
                return imageView
            }
            let imageView = AssetThumbImageView()
            imageView.tag = index
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            return imageView
        }()
        imageViews[index] = imageView
        
        // Layout
        layout(imageView: imageView, at: index)
        
        // Image generetor
        let secondsPerImage = Double(imageSize.width / widthPerSecond)
        let seconds = secondsPerImage * Double(index)
        let time = CMTime(seconds: seconds, preferredTimescale: asset.duration.timescale)
        imageView.configure(asset: asset, at: time)
        imageView.configureDebugIndexLabel(index: index)
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
    
    private func updateLayoutIfNeed(imageView: AssetThumbImageView, at index: Int) {
        if imageView.tag == index {
            return
        }
        layout(imageView: imageView, at: index)
    }
    
}

class AssetThumbImageView: UIImageView {
    
    var imageGenerator: AVAssetImageGenerator?
    
    func prepareForReuse() {
        imageGenerator?.cancelAllCGImageGeneration()
    }
    
    func configure(asset: AVAsset, at time: CMTime) {
        if let imageGenerator = imageGenerator, imageGenerator.asset == asset {
            // Same image generator don't recreate
        } else {
            imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator?.appliesPreferredTrackTransform = true
        }
        
        let imageSize = bounds.size
        let imageWidth = imageSize.width * UIScreen.main.scale
        let imageHeight = imageSize.height * UIScreen.main.scale
        if let naturalSize = asset.tracks.first?.naturalSize {
            let widthRatio = imageWidth / naturalSize.width
            let heightRatio = imageHeight / naturalSize.height
            if widthRatio > heightRatio {
                let height = round(naturalSize.height * widthRatio)
                imageGenerator?.maximumSize = CGSize(width: imageWidth, height: height)
            } else {
                let width = round(naturalSize.width * heightRatio)
                imageGenerator?.maximumSize = CGSize(width: width, height: imageHeight)
            }
        } else {
            imageGenerator?.maximumSize = CGSize(width: imageWidth, height: imageHeight)
        }
        imageGenerator?.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)], completionHandler: { [weak self] (time, image, actualTime, result, error) in
            guard let strongSelf = self else { return }
            if result == .succeeded, let image = image {
                DispatchQueue.main.async {
                    strongSelf.image = UIImage(cgImage: image)
                }
            } else if let error = error {
                print("Image generator copyCGImage error: \(error.localizedDescription)")
            }
        })
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
