//
//  VideoRangeView.swift
//  XDtv
//
//  Created by Vito on 12/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoRangeViewDelegate: class {
    func videoRangeViewBeginUpdateLeft(_ view: VideoRangeView)
    func videoRangeView(_ view: VideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool)
    func videoRangeViewDidEndUpdateLeftOffset(_ view: VideoRangeView)
    
    func videoRangeViewBeginUpdateRight(_ view: VideoRangeView)
    func videoRangeView(_ view: VideoRangeView, updateRightOffset offset: CGFloat, auto: Bool)
    func videoRangeViewDidEndUpdateRightOffset(_ view: VideoRangeView)
}

class VideoRangeView: TimeLineRangeView {
    
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
    var earEdgeInset: CGFloat = 30 {
        didSet {
            leftPaddingViewConstraint.constant = earEdgeInset
            rightPaddingViewConstraint.constant = -earEdgeInset
        }
    }
    
    private(set) var leftPaddingView: UIView!
    private(set) var rightPaddingView: UIView!
    var leftPaddingViewConstraint: NSLayoutConstraint!
    var rightPaddingViewConstraint: NSLayoutConstraint!
    
    private(set) var blueCoverView: UIView!
    private(set) var coverView: UIView!
    
    private(set) var contentView: RangeContentView!
    private(set) var leftEar: RangeViewEarView!
    private(set) var rightEar: RangeViewEarView!
    private(set) var backgroundImageView: UIImageView!
    private(set) var timeLabel: UILabel!
    
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
        backgroundImageView.backgroundColor = UIColor.white
        addSubview(backgroundImageView)
        backgroundImageView.layer.cornerRadius = 4
        backgroundImageView.clipsToBounds = true
        
        
        coverView = UIView()
        addSubview(coverView)
        coverView.isUserInteractionEnabled = false
        coverView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        coverView.isHidden = true
        
        blueCoverView = UIView()
        addSubview(blueCoverView)
        blueCoverView.isUserInteractionEnabled = false
        blueCoverView.backgroundColor = UIColor.clear
        
        timeLabel = UILabel()
        timeLabel.font = UIFont.boldSystemFont(ofSize: 11)
        timeLabel.textColor = UIColor.white
        addSubview(timeLabel)
        
        
        leftEar = RangeViewEarView()
        leftEar.imageView.image = UIImage.init(named: "lockUnselectedLeft")
        leftEar.imageView.highlightedImage = UIImage.init(named: "editor_timer_dot")
        addSubview(leftEar)
        
        rightEar = RangeViewEarView()
        rightEar.imageView.image = UIImage.init(named: "lockUnselectedRight")
        rightEar.imageView.highlightedImage = UIImage.init(named: "editor_timer_dot")
        addSubview(rightEar)
        
        leftPaddingView = UIView()
        addSubview(leftPaddingView)
        leftPaddingView.isUserInteractionEnabled = false
        leftPaddingView.backgroundColor = UIColor.iosBlackThree
        
        rightPaddingView = UIView()
        addSubview(rightPaddingView)
        rightPaddingView.isUserInteractionEnabled = false
        rightPaddingView.backgroundColor = UIColor.iosBlackThree
        
        leftPaddingView.translatesAutoresizingMaskIntoConstraints = false
        let leftConstraint = leftPaddingView.leftAnchor.constraint(equalTo: leftEar.rightAnchor)
        leftConstraint.isActive = true
        leftPaddingView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftPaddingView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftPaddingViewConstraint = leftPaddingView.widthAnchor.constraint(equalToConstant: 2)
        leftPaddingViewConstraint.isActive = true
        
        rightPaddingView.translatesAutoresizingMaskIntoConstraints = false
        let rightConstraint = rightPaddingView.rightAnchor.constraint(equalTo: rightEar.leftAnchor)
        rightConstraint.isActive = true
        rightPaddingView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightPaddingView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightPaddingViewConstraint = rightPaddingView.widthAnchor.constraint(equalToConstant: 2)
        rightPaddingViewConstraint.isActive = true
        
        // Background ImageView
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
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
        
        inactiveEar(animated: false)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        let timeLabelTopConstraint = timeLabel.topAnchor.constraint(equalTo: topAnchor)
        timeLabelTopConstraint.constant = 4
        timeLabelTopConstraint.isActive = true
        
        let timeLabelLeftConstraint = timeLabel.leftAnchor.constraint(equalTo: leftAnchor)
        timeLabelLeftConstraint.constant = 4
        timeLabelLeftConstraint.isActive = true
    }
    
    override var intrinsicContentSize: CGSize {
        let width = contentView.contentWidth + contentInset.left + contentInset.right
        return CGSize(width: width, height: contentHeight)
    }
    
    func loadContentView(_ contentView: RangeContentView) {
        if let previousContentView = self.contentView {
            previousContentView.removeFromSuperview()
        }
        self.contentView = contentView
        insertSubview(contentView, aboveSubview: backgroundImageView)
        
        // VideoContent View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        videoContentLeftConstraint = contentView.leftAnchor.constraint(equalTo: leftAnchor)
        videoContentLeftConstraint.constant = contentInset.left
        videoContentLeftConstraint.isActive = true
        
        videoContentRightConstraint = contentView.rightAnchor.constraint(equalTo: rightAnchor)
        videoContentRightConstraint.constant = -contentInset.right
        videoContentRightConstraint.isActive = true
        
        videoContentTopConstraint = contentView.topAnchor.constraint(equalTo: topAnchor)
        videoContentTopConstraint.constant = contentInset.top
        videoContentTopConstraint.isActive = true
        
        videoContentBottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        videoContentBottomConstraint.constant = -contentInset.bottom
        videoContentBottomConstraint.isActive = true
        
        coverView.translatesAutoresizingMaskIntoConstraints = false
        coverView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        coverView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        coverView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        coverView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        blueCoverView.translatesAutoresizingMaskIntoConstraints = false
        blueCoverView.leftAnchor.constraint(equalTo: coverView.leftAnchor).isActive = true
        blueCoverView.rightAnchor.constraint(equalTo: coverView.rightAnchor).isActive = true
        blueCoverView.topAnchor.constraint(equalTo: coverView.topAnchor).isActive = true
        blueCoverView.bottomAnchor.constraint(equalTo: coverView.bottomAnchor).isActive = true
        
        rightEar.imageView.isHighlighted = contentView.reachEnd() && !contentView.supportUnlimitTime
        leftEar.imageView.isHighlighted = contentView.reachHead() && !contentView.supportUnlimitTime
    }
    
    
    // MARK: - Expand touch
    var topInset: CGFloat = 0
    var leftInset: CGFloat = 15
    var rightInset: CGFloat = 15
    var bottomInset: CGFloat = 0
    
    var enlargeInset: UIEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15) {
        didSet {
            self.topInset = enlargeInset.top
            self.bottomInset = enlargeInset.bottom
            self.leftInset = enlargeInset.left
            self.rightInset = enlargeInset.right
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let x = bounds.origin.x - leftInset
        let y = bounds.origin.y - topInset
        let width = bounds.size.width + rightInset + leftInset
        let height = bounds.size.height + bottomInset + topInset
        let rect = CGRect(x: x, y: y, width: width, height: height)
        if rect.equalTo(bounds) {
            return super.point(inside: point, with: event)
        }
        
        if rect.contains(point) && !isHidden {
            return true
        }
        
        return false
    }
    
    
    func reloadUI() {
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
        if gesture.state == .began {
            if gesture.view == rightEar {
                delegate?.videoRangeViewBeginUpdateRight(self)
            } else {
                delegate?.videoRangeViewBeginUpdateLeft(self)
            }
        }
        
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
        let width = adjustWidth(width)
        let previousWidth = contentView.contentWidth
        contentView.expand(contentWidth: width, left: false)
        let offset = contentView.contentWidth - previousWidth
        invalidateIntrinsicContentSize()
        delegate?.videoRangeView(self, updateRightOffset: offset, auto: auto)
        rightEar.imageView.isHighlighted = contentView.reachEnd() && !contentView.supportUnlimitTime
        changeTime(left: false)
        return offset
    }
    
    fileprivate func adjustWidth(_ width: CGFloat) -> CGFloat {
        return width
    }
    
    @discardableResult
    fileprivate func expandLeftEar(width: CGFloat, auto: Bool) -> CGFloat {
        let previousWidth = contentView.contentWidth
        contentView.expand(contentWidth: -width, left: true)
        let offset = contentView.contentWidth - previousWidth
        invalidateIntrinsicContentSize()
        delegate?.videoRangeView(self, updateLeftOffset: -offset, auto: auto)
        leftEar.imageView.isHighlighted = contentView.reachHead() && !contentView.supportUnlimitTime
        changeTime(left: true)
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
            changeTime(left: true)
            if newValue {
                activeEar()
            } else {
                inactiveEar()
            }
        }
    }
    
    fileprivate func activeEar(animated: Bool = true) {
        timeLabel.isHidden = false
        leftPaddingView.isHidden = true
        rightPaddingView.isHidden = true
        leftEar.isUserInteractionEnabled = true
        rightEar.isUserInteractionEnabled = true
        func operations() {
            blueCoverView.backgroundColor = UIColor.iosAzure.withAlphaComponent(0.4)
            coverView.alpha = 0.0
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
        timeLabel.isHidden = true
        leftPaddingView.isHidden = false
        rightPaddingView.isHidden = false
        leftEar.isUserInteractionEnabled = false
        rightEar.isUserInteractionEnabled = false
        func operations() {
            blueCoverView.backgroundColor = UIColor.clear
            coverView.alpha = 1.0
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
    
    fileprivate func changeTime(left: Bool) {
        let duration = contentView.endTime - contentView.startTime
        timeLabel.text = String(format: "%.1f\"", duration.seconds)
        timeLabel.center = {
            var center = timeLabel.center
            if left {
                if duration.seconds < 0.5 {
                    center.x = leftEar.frame.origin.x - timeLabel.frame.size.width / 2 - 4
                } else {
                    center.x = leftEar.frame.origin.x + leftEar.frame.size.width + timeLabel.frame.size.width / 2 + 4
                }
            } else {
                if duration.seconds < 0.5 {
                    center.x = rightEar.frame.origin.x + rightEar.frame.size.width + timeLabel.frame.size.width / 2 + 4
                } else {
                    center.x = rightEar.frame.origin.x - timeLabel.frame.size.width / 2 - 4
                }
            }
            return center
        }()
    }
    
}

class RangeViewEarView: UIView {
    var imageView: UIImageView!
    
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
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    var topInset: CGFloat = 10
    var leftInset: CGFloat = 15
    var rightInset: CGFloat = 15
    var bottomInset: CGFloat = 10
    
    var enlargeInset: UIEdgeInsets = UIEdgeInsetsMake(10, 15, 10, 15) {
        didSet {
            self.topInset = enlargeInset.top
            self.bottomInset = enlargeInset.bottom
            self.leftInset = enlargeInset.left
            self.rightInset = enlargeInset.right
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let x = bounds.origin.x - leftInset
        let y = bounds.origin.y - topInset
        let width = bounds.size.width + rightInset + leftInset
        let height = bounds.size.height + bottomInset + topInset
        let rect = CGRect(x: x, y: y, width: width, height: height)
        if rect.equalTo(bounds) {
            return super.point(inside: point, with: event)
        }
        
        if rect.contains(point) && !isHidden {
            return true
        }
        
        return false
    }
}

