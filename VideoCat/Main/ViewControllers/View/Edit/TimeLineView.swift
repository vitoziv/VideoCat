//
//  TimeLineView.swift
//  VideoCat
//
//  Created by Vito on 13/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class TimeLineView: UIView {

    private(set) var scrollView: UIScrollView!
    private(set) var contentView: UIView!
    private(set) var centerLineView: UIView!
    
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
        
        centerLineView = UIView()
        addSubview(centerLineView)
        centerLineView.isUserInteractionEnabled = false
        centerLineView.backgroundColor = UIColor.orange
        
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
        
        centerLineView.translatesAutoresizingMaskIntoConstraints = false
        centerLineView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        centerLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        centerLineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        centerLineView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLineViewAction(_:)))
        addGestureRecognizer(tapGesture)
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
    
    func resignVideoRangeView() {
        rangeViews.filter({ $0.isEditActive }).forEach({ $0.isEditActive = false })
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
    
    func append(asset: AVAsset, at index: Int = 0) {
        // TODO: 添加到当前时间点，最接近的地方。
        // 1. 如果没有 asset，直接添加
        // 2. 如果当前时间线压在一个 asset 上，判断时间线在 asset 的偏左边还是偏右边，然后放到最近的位置
        
        let videoRangeView = VideoRangeView()
        videoRangeView.videoContentView.widthPerSecond = 10
        videoRangeView.contentInset = UIEdgeInsetsMake(2, videoRangeViewEarWidth, 2, videoRangeViewEarWidth)
        videoRangeView.delegate = self
        let tapContentGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentAction(_:)))
        videoRangeView.addGestureRecognizer(tapContentGesture)
        contentView.insertSubview(videoRangeView, at: 0)
        videoRangeView.configure(asset: asset)
        
        videoRangeView.translatesAutoresizingMaskIntoConstraints = false
        videoRangeView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        videoRangeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        if rangeViews.count == 0 {
            rangeViews.append(videoRangeView)
            videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: contentView.leftAnchor)
            videoRangeView.leftConstraint?.isActive = true
            videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
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
                
                videoRangeView.rightConstraint = videoRangeView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
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
                
                videoRangeView.leftConstraint = videoRangeView.leftAnchor.constraint(equalTo: contentView.leftAnchor)
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
    
}

extension TimeLineView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let showingRangeViews = rangeViews.filter { (view) -> Bool in
            let rect = view.superview!.convert(view.frame, to: scrollView)
            let intersects = scrollView.bounds.intersects(rect)
            return intersects
        }
        showingRangeViews.forEach({ $0.videoContentView.updateThumbIfNeed() })
    }
}

// MARK: - VideoRangeViewDelegate

extension TimeLineView: VideoRangeViewDelegate {
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
