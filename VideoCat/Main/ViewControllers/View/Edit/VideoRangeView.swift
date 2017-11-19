//
//  VideoRangeView.swift
//  VideoCat
//
//  Created by Vito on 12/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class VideoRangeView: UIView {
    
    var contentHeight: CGFloat = 44
    /// Conent will be displayed inside the inset
    var contentInset: UIEdgeInsets = UIEdgeInsetsMake(2, 24, 2, 24) {
        didSet {
            leftEarWidthConstraint.constant = contentInset.left
            rightEarWidthConstraint.constant = contentInset.right
            
            videoContentLeftConstraint.constant = contentInset.left
            videoContentTopConstraint.constant = contentInset.top
            videoContentRightConstraint.constant = -contentInset.right
            videoContentBottomConstraint.constant = -contentInset.bottom
        }
    }
    
    private(set) var videoContentView: VideoRangeContentView!
    private(set) var leftEar: UIImageView!
    private(set) var rightEar: UIImageView!
    private(set) var backgroundImageView: UIImageView!
    
    private var leftEarWidthConstraint: NSLayoutConstraint!
    private var rightEarWidthConstraint: NSLayoutConstraint!
    
    private var videoContentLeftConstraint: NSLayoutConstraint!
    private var videoContentTopConstraint: NSLayoutConstraint!
    private var videoContentRightConstraint: NSLayoutConstraint!
    private var videoContentBottomConstraint: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundImageView = UIImageView()
        backgroundImageView.backgroundColor = UIColor(white: 0, alpha: 1)
        addSubview(backgroundImageView)
        
        videoContentView = VideoRangeContentView()
        addSubview(videoContentView)
        
        leftEar = EnlargeImageView()
        leftEar.backgroundColor = UIColor.purple
        leftEar.isUserInteractionEnabled = true
        addSubview(leftEar)
        
        rightEar = EnlargeImageView()
        rightEar.backgroundColor = UIColor.purple
        rightEar.isUserInteractionEnabled = true
        addSubview(rightEar)
        
        // Background ImageView
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // VideoContent View
        videoContentView.translatesAutoresizingMaskIntoConstraints = false
        videoContentLeftConstraint = videoContentView.leftAnchor.constraint(equalTo: leftAnchor)
        videoContentLeftConstraint.constant = contentInset.left
        videoContentLeftConstraint.isActive = true
        
        videoContentRightConstraint = videoContentView.rightAnchor.constraint(equalTo: rightAnchor)
        videoContentRightConstraint.constant = -contentInset.right
        videoContentRightConstraint.isActive = true
        
        videoContentTopConstraint = videoContentView.topAnchor.constraint(equalTo: topAnchor)
        videoContentTopConstraint.constant = contentInset.top
        videoContentTopConstraint.isActive = true
        
        videoContentBottomConstraint = videoContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        videoContentBottomConstraint.constant = -contentInset.bottom
        videoContentBottomConstraint.isActive = true
        
        // Left Ear
        leftEar.translatesAutoresizingMaskIntoConstraints = false
        leftEar.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        leftEar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftEar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftEarWidthConstraint = leftEar.widthAnchor.constraint(equalToConstant: contentInset.left)
        leftEarWidthConstraint.isActive = true
        
        // Right Ear
        rightEar.translatesAutoresizingMaskIntoConstraints = false
        rightEar.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rightEar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightEar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightEarWidthConstraint = rightEar.widthAnchor.constraint(equalToConstant: contentInset.right)
        rightEarWidthConstraint.isActive = true
        
        let leftPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panEarAction(_:)))
        leftEar.addGestureRecognizer(leftPanGesture)
        
        let rightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panEarAction(_:)))
        rightEar.addGestureRecognizer(rightPanGesture)
    }
    
    override var intrinsicContentSize: CGSize {
        let width = videoContentView.contentWidth + contentInset.left + contentInset.right
        return CGSize(width: width, height: contentHeight)
    }

    func configure(asset: AVAsset?) {
        videoContentView.asset = asset
        if let duration = asset?.duration {
            videoContentView.endTime = duration
        }
        
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    
    // MARK: - Action
    
    @objc private func panEarAction(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        if gesture.view == rightEar {
            videoContentView.expand(contentWidth: translation.x, left: false)
        } else {
            videoContentView.expand(contentWidth: -translation.x, left: true)
        }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        gesture.setTranslation(CGPoint.zero, in: gesture.view)
    }
    
}

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
        }
    }
    var endTime: CMTime = kCMTimeZero{
        didSet {
            timeLabel.text = String(format: "(%.1f, %.1f)", startTime.seconds, endTime.seconds - startTime.seconds)
        }
    }
    
    var widthPerSecond: CGFloat = 0
    /// preload left and right image thumb, if preloadCount is 2, then will preload 2 left image thumbs and 2 right image thumbs
    var preloadCount: Int = 2
    
    var contentWidth: CGFloat {
        let duration = endTime.seconds - startTime.seconds
        return round(CGFloat(duration) * widthPerSecond)
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
        
        let startOffset = CGFloat(startTime.seconds) * widthPerSecond
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
            startTime = CMTime(seconds: startSeconds, preferredTimescale: 10000)
        } else {
            guard let asset = asset else {
                return
            }
            let maxDuration: Double = asset.duration.seconds
            let endSeconds = max(min(endTime.seconds + Double(seconds), maxDuration), startTime.seconds)
            endTime = CMTime(seconds: endSeconds, preferredTimescale: 10000)
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
            layout(imageView: imageView, at: index)
            return
        }
        
        let imageView: AssetThumbImageView = {
            if let imageView = reuseableImageViews.first {
                reuseableImageViews.removeFirst()
                imageView.prepareForReuse()
                return imageView
            }
            let imageView = AssetThumbImageView()
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
                    let startOffset = CGFloat(startTime.seconds) * widthPerSecond
                    constraint.constant = round((CGFloat(index) * imageSize.width) - startOffset)
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
            let startOffset = CGFloat(startTime.seconds) * widthPerSecond
            imageViewLeftConstraint.constant = round((CGFloat(index) * imageSize.width) - startOffset)
            imageViewLeftConstraint.isActive = true
            imageViewLeftConstraint.identifier = "VideoRangeContentView-AssetThumbImageView"
            imageView.widthAnchor.constraint(equalToConstant: imageSize.width).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: imageSize.height).isActive = true
        }
        
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
