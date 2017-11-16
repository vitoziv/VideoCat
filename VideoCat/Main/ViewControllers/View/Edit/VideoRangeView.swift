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
    
    var asset: AVAsset?
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
    
    var contentWidth: CGFloat {
        let duration = endTime.seconds - startTime.seconds
        return round(CGFloat(duration) * widthPerSecond)
    }
    
    private(set) var timeLabel: UILabel!
    
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
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.setFillColor(UIColor.orange.cgColor)
        context.fill(rect)
        
        print("draw in rect \(rect)")
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
    
}
