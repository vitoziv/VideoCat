//
//  TimeLineView.swift
//  VideoCat
//
//  Created by Vito on 13/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import RxCocoa

class TimeLineView: UIView {

    private(set) var scrollView: UIScrollView!
    private(set) var contentView: UIView!
    fileprivate(set) var videoListContentView: UIView!
    private(set) var centerLineView: UIView!
    private(set) var totalTimeLabel: UILabel!
    
    private(set) var scrollContentHeightConstraint: NSLayoutConstraint!
    
    private(set) var rangeViews: [VideoRangeView] = []
    
    var rangeViewsIndex: Int {
        var index = 0
        let center = centerLineView.center
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                index = i
                break
            }
        }
        
        return index
    }
    var videoRangeViewEarWidth: CGFloat = 24
    var widthPerSecond: CGFloat = 60
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        scrollView = UIScrollView()
        addSubview(scrollView)
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentSize = CGSize(width: 0, height: bounds.height)
        scrollView.delegate = self
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        videoListContentView = UIView()
        contentView.addSubview(videoListContentView)
        
        centerLineView = UIView()
        addSubview(centerLineView)
        centerLineView.isUserInteractionEnabled = false
        centerLineView.backgroundColor = UIColor.orange
        
        totalTimeLabel = UILabel()
        addSubview(totalTimeLabel)
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.font = UIFont.systemFont(ofSize: 16)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        scrollContentHeightConstraint = contentView.heightAnchor.constraint(equalToConstant: 60)
        scrollContentHeightConstraint.isActive = true
        
        videoListContentView.translatesAutoresizingMaskIntoConstraints = false
        videoListContentView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        videoListContentView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        videoListContentView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        videoListContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        centerLineView.translatesAutoresizingMaskIntoConstraints = false
        centerLineView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        centerLineView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        let timeLabelRightConstraint = totalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor)
        timeLabelRightConstraint.constant = -15
        timeLabelRightConstraint.isActive = true
        let timeLabelBottomConstraint = totalTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        timeLabelBottomConstraint.constant = -10
        timeLabelBottomConstraint.isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLineViewAction(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = bounds.width * 0.5 - videoRangeViewEarWidth
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    // MARK: - Actions
    
    @objc private func tapContentAction(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            if let view = recognizer.view as? VideoRangeView, !view.isEditActive {
                view.superview?.bringSubview(toFront: view)
                view.isEditActive = true
                rangeViews.filter({ $0 != view && $0.isEditActive }).forEach({ $0.isEditActive = false })
            }
        }
    }
    
    @objc private func tapLineViewAction(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: recognizer.view)
        var tapOnVideoRangeView = false
        for view in rangeViews {
            let rect = view.superview!.convert(view.frame, to: self)
            if rect.contains(point) {
                tapOnVideoRangeView = true
                break
            }
        }
        if !tapOnVideoRangeView {
            resignVideoRangeView()
        }
    }
    
    // MARK: - Data
    
    func resignVideoRangeView() {
        rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
    }
    
    func appendVideoRangeView(configuration: (VideoRangeView) -> Void, at index: Int = Int.max) {
        // 添加到当前时间点，最接近的地方。
        let videoRangeView = VideoRangeView()
        configuration(videoRangeView)
        videoRangeView.contentView.widthPerSecond = widthPerSecond
        videoRangeView.contentInset = UIEdgeInsetsMake(2, videoRangeViewEarWidth, 2, videoRangeViewEarWidth)
        videoRangeView.delegate = self
        videoRangeView.isEditActive = false
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        videoRangeView.addGestureRecognizer(tapContentGesture)
        videoListContentView.insertSubview(videoRangeView, at: 0)
        
        videoRangeView.translatesAutoresizingMaskIntoConstraints = false
        videoRangeView.topAnchor.constraint(equalTo: videoListContentView.topAnchor).isActive = true
        videoRangeView.bottomAnchor.constraint(equalTo: videoListContentView.bottomAnchor).isActive = true
        if rangeViews.count == 0 {
            rangeViews.append(videoRangeView)
            videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
            videoRangeView.leftConstraint?.isActive = true
            videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
            videoRangeView.rightConstraint?.isActive = true
        } else {
            if index >= rangeViews.count {
                let leftVideoRangeView = rangeViews.last!
                rangeViews.append(videoRangeView)
                if let rightConstraint = leftVideoRangeView.rightConstraint {
                    rightConstraint.isActive = false
                }
                let leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                videoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: videoListContentView.rightAnchor)
                videoRangeView.rightConstraint?.isActive = true
            } else if index == 0 {
                rangeViews.insert(videoRangeView, at: index)
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
                
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: videoListContentView.leftAnchor)
                videoRangeView.leftConstraint?.isActive = true
            } else {
                rangeViews.insert(videoRangeView, at: index)
                let leftVideoRangeView = rangeViews[index - 1]
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: leftVideoRangeView.rightAnchor)
                videoRangeView.leftConstraint?.constant = -videoRangeViewEarWidth * 2
                videoRangeView.leftConstraint?.isActive = true
                
                let rightVideoRangeView = rangeViews[index + 1]
                if let leftConstraint = rightVideoRangeView.leftConstraint {
                    leftConstraint.isActive = false
                }
                let leftConstraint = rightVideoRangeView.leftAnchor.constraint(equalTo: videoRangeView.rightAnchor)
                leftConstraint.constant = -videoRangeViewEarWidth * 2
                leftConstraint.isActive = true
                rightVideoRangeView.leftConstraint = leftConstraint
            }
        }
    }
    
    func removeAllRangeViews() {
        rangeViews.forEach { (view) in
            view.removeFromSuperview()
        }
        rangeViews.removeAll()
    }
    
    func adjustCollectionViewOffset(time: CMTime) {
        if !time.isValid { return }
        let time = max(time, kCMTimeZero)
        let offsetX = getOffsetX(at: time).0
        if !offsetX.isNaN {
            scrollView.delegate = nil
            scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
            displayRangeViewsIfNeed()
            scrollView.delegate = self
        }
    }
    
    func showingRangeView() -> [VideoRangeView] {
        let showingRangeViews = rangeViews.filter { (view) -> Bool in
            let rect = view.superview!.convert(view.frame, to: scrollView)
            let intersects = scrollView.bounds.intersects(rect)
            return intersects
        }
        return showingRangeViews
    }
    
    fileprivate func displayRangeViewsIfNeed() {
        let showingRangeViews = showingRangeView()
        showingRangeViews.forEach({
            $0.contentView.updateDataIfNeed()
        })
    }
    
    fileprivate func timeDidChanged() {
        var duration: CGFloat = 0
        rangeViews.forEach { (view) in
            duration = duration + view.frame.size.width / widthPerSecond
        }
        totalTimeLabel.text = String.init(format: "%.1f", duration)
    }
    
    // MARK: offset
    
    func getOffsetX(at time: CMTime) -> (CGFloat, Int) {
        var offsetX: CGFloat = -scrollView.contentInset.left
        guard time.isValid else { return (offsetX, 0) }
        
        var duration = time
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let contentDuration = rangeView.contentView.endTime - rangeView.contentView.startTime
            if duration <= contentDuration {
                index = i
                break
            } else {
                duration = duration - contentDuration
            }
        }
        offsetX = offsetX + CGFloat(time.seconds) * widthPerSecond
        
        return (offsetX, index)
    }
    
    func getTime(at offsetX: CGFloat) -> (CMTime, Int) {
        var offsetX = offsetX + scrollView.contentInset.left
        let duration = CMTime.init(seconds: Double(offsetX / widthPerSecond), preferredTimescale: 600)
        var index = 0
        for (i, rangeView) in rangeViews.enumerated() {
            let width = rangeView.contentView.contentWidth
            if offsetX <= width {
                index = i
                break
            } else {
                offsetX = offsetX - width
            }
        }
        
        return (duration, index)
    }
    
}

extension TimeLineView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        displayRangeViewsIfNeed()
    }
    
    
}

// MARK: - VideoRangeViewDelegate

extension TimeLineView: VideoRangeViewDelegate {
    func videoRangeViewBeginUpdateLeft(_ view: VideoRangeView) {
        // TODO: 替换当前显示的 player，要能做到预览当前选中片段的完整视频
    }
    
    func videoRangeViewBeginUpdateRight(_ view: VideoRangeView) {
        // TODO: 替换当前显示的 player，要能做到预览当前选中片段的完整视频
    }
    
    func videoRangeView(_ view: VideoRangeView, updateLeftOffset offset: CGFloat, auto: Bool) {
        if auto {
            return
        }
        
        var inset = scrollView.contentInset
        inset.left = scrollView.frame.width
        scrollView.contentInset = inset
        
        var contentOffset = scrollView.contentOffset
        contentOffset.x -= offset
        scrollView.setContentOffset(contentOffset, animated: false)
        
        
        timeDidChanged()
    }
    
    func videoRangeViewDidEndUpdateLeftOffset(_ view: VideoRangeView) {
        var inset = scrollView.contentInset
        inset.left = inset.right
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentInset = inset
        }
    }
    
    func videoRangeView(_ view: VideoRangeView, updateRightOffset offset: CGFloat, auto: Bool) {
        if auto {
            var contentOffset = scrollView.contentOffset
            contentOffset.x += offset
            scrollView.setContentOffset(contentOffset, animated: false)
        } else {
            var inset = scrollView.contentInset
            inset.right = scrollView.frame.width
            scrollView.contentInset = inset
        }
        
        timeDidChanged()
    }
    
    func videoRangeViewDidEndUpdateRightOffset(_ view: VideoRangeView) {
        var inset = scrollView.contentInset
        inset.right = inset.left
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentInset = inset
        }
    }
}

// MARK: - Helper

extension TimeLineView {
    
    var nextRangeViewIndex: Int {
        var index = 0
        let center = centerLineView.center
        for (i, view) in rangeViews.enumerated() {
            let rect = view.superview!.convert(view.frame, to: centerLineView.superview!)
            if rect.contains(center) {
                if center.x - rect.origin.x < rect.maxX - center.x {
                    // On left side
                    index = i
                } else {
                    // On right side
                    index = i + 1
                }
                break
            }
        }
        
        return index
    }
    
}
