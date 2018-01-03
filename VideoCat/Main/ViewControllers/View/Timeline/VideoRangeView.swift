//
//  VideoRangeView.swift
//  VideoCat
//
//  Created by Vito on 12/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoRangeViewDelegate: class {
    func videoRangeView(_ view: VideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool)
    func videoRangeViewDidEndUpdateLeftOffset(_ view: VideoRangeView)
    
    func videoRangeView(_ view: VideoRangeView, updateRightOffset offset: CGFloat, auto: Bool)
    func videoRangeViewDidEndUpdateRightOffset(_ view: VideoRangeView)
}

class VideoRangeView: UIView {
    
    weak var delegate: VideoRangeViewDelegate?
    fileprivate lazy var displayTriggerMachine = DisplayTriggerMachine()
    
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
    /// This value defined when should change content size and ear position automatically
    /// while user dragging ear to the edge of window.
    var autoScrollInset: CGFloat = 100
    var earEdgeInset: CGFloat = 30
    
    var leftConstraint: NSLayoutConstraint?
    var rightConstraint: NSLayoutConstraint?
    
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
        backgroundImageView.backgroundColor = UIColor.purple
        addSubview(backgroundImageView)
        
        videoContentView = VideoRangeContentView()
        addSubview(videoContentView)
        
        leftEar = EnlargeImageView()
        leftEar.backgroundColor = UIColor.purple
        addSubview(leftEar)
        
        rightEar = EnlargeImageView()
        rightEar.backgroundColor = UIColor.purple
        addSubview(rightEar)
        
        inactiveEar(animated: false)
        
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
    
    // MARK: - Left and right ear gesture handle
    
    private var autoScrollSpeed: CGFloat = 0
    private var autoScrollType: AutoScrollType = .none
    enum AutoScrollType: Int {
        case none
        case left
        case right
    }
    private var panGesturePreviousTranslation = CGPoint.zero
    
    @objc private func panEarAction(_ gesture: UIPanGestureRecognizer) {
        // Check whether gesture should trigger automatic scroll
        let windowLocation = gesture.view!.superview!.convert(gesture.view!.center, to: window)
        let windowBounds = window!.bounds // No window, no gesture
        if (windowLocation.x < autoScrollInset && panGesturePreviousTranslation.x < 0) ||
            (windowLocation.x > (windowBounds.width - autoScrollInset) && panGesturePreviousTranslation.x > 0) {
            autoScrollEar(gesture)
            displayTriggerMachine.start()
        } else {
            displayTriggerMachine.pause()
            cleanUpAutoScrolValues()
        }
        
        let translation = gesture.translation(in: gesture.view)
        let outOfControl = (windowLocation.x < earEdgeInset && panGesturePreviousTranslation.x > translation.x) ||
            ((windowLocation.x > windowBounds.width - earEdgeInset) && panGesturePreviousTranslation.x < translation.x)
        if !outOfControl {
            normalPanEar(gesture)
        }
        
        // No matter what happened, call this
        if gesture.state == .ended || gesture.state == .cancelled {
            // Clean up auto scroll values
            cleanUpAutoScrolValues()
            
            if gesture.view == rightEar {
                delegate?.videoRangeViewDidEndUpdateRightOffset(self)
            } else {
                delegate?.videoRangeViewDidEndUpdateLeftOffset(self)
            }
        }
    }
    
    fileprivate func autoScrollEar(_ gesture: UIPanGestureRecognizer) {
        let windowLocation = gesture.view!.superview!.convert(gesture.view!.center, to: window)
        let windowBounds = window!.bounds // No window, no gesture
        
        if windowLocation.x > (windowBounds.width - autoScrollInset) {
            let scrollInset = autoScrollInset - (windowBounds.width - windowLocation.x)
            autoScrollSpeed = min(scrollInset, autoScrollInset) * 0.1
        } else if windowLocation.x < autoScrollInset {
            let scrollInset = autoScrollInset - windowLocation.x
            autoScrollSpeed = -min(scrollInset, autoScrollInset) * 0.1
        }
        
        if gesture.view == rightEar {
            if autoScrollType != .right {
                autoScrollType = .right
                displayTriggerMachine.triggerOperation = { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.expandRightEar(width: strongSelf.autoScrollSpeed, auto: true)
                }
            }
        } else if gesture.view == leftEar {
            if autoScrollType != .left {
                autoScrollType = .left
                displayTriggerMachine.triggerOperation = { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.expandLeftEar(width: strongSelf.autoScrollSpeed, auto: true)
                }
            }
        }
    }
    
    fileprivate func normalPanEar(_ gesture: UIPanGestureRecognizer) {
        // normal drag
        let translation = gesture.translation(in: gesture.view)
        let offset = translation.x - panGesturePreviousTranslation.x
        
        var actulOffset = offset
        if gesture.view == rightEar {
            actulOffset = expandRightEar(width: offset, auto: false)
        } else {
            actulOffset = -expandLeftEar(width: offset, auto: false)
        }
        panGesturePreviousTranslation.x += actulOffset
        
        if gesture.state == .ended || gesture.state == .cancelled {
            panGesturePreviousTranslation = CGPoint.zero
        }
    }
    
    @discardableResult
    fileprivate func expandRightEar(width: CGFloat, auto: Bool) -> CGFloat {
        let previousWidth = videoContentView.contentWidth
        videoContentView.expand(contentWidth: width, left: false)
        let offset = videoContentView.contentWidth - previousWidth
        invalidateIntrinsicContentSize()
        delegate?.videoRangeView(self, updateRightOffset: offset, auto: auto)
        return offset
    }
    
    @discardableResult
    fileprivate func expandLeftEar(width: CGFloat, auto: Bool) -> CGFloat {
        let previousWidth = videoContentView.contentWidth
        videoContentView.expand(contentWidth: -width, left: true)
        let offset = videoContentView.contentWidth - previousWidth
        invalidateIntrinsicContentSize()
        delegate?.videoRangeView(self, updateLeftOffset: -offset, auto: auto)
        return offset
    }
    
    fileprivate func cleanUpAutoScrolValues() {
        autoScrollSpeed = 0
        autoScrollType = .none
        displayTriggerMachine.pause()
    }
    
    // MARK: - Active & Inactive manage
    
    var isEditActive: Bool {
        get {
            return leftEar.isUserInteractionEnabled
        }
        set {
            if newValue {
                activeEar()
            } else {
                inactiveEar()
            }
        }
    }
    
    fileprivate func activeEar(animated: Bool = true) {
        leftEar.isUserInteractionEnabled = true
        rightEar.isUserInteractionEnabled = true
        func operations() {
            backgroundImageView.alpha = 1.0
            leftEar.alpha = 1.0
            rightEar.alpha = 1.0
        }
        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseInOut],
                           animations: operations,
                           completion: nil)
        } else {
            operations()
        }
    }
    
    fileprivate func inactiveEar(animated: Bool = true) {
        leftEar.isUserInteractionEnabled = false
        rightEar.isUserInteractionEnabled = false
        func operations() {
            backgroundImageView.alpha = 0.0
            leftEar.alpha = 0.0
            rightEar.alpha = 0.0
        }
        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseInOut],
                           animations: operations,
                           completion: nil)
        } else {
            operations()
        }
    }
    
}
