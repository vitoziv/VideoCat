//
//  TimeRangePickerView.swift
//  TimeRange
//
//  Created by Vito on 27/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

protocol TimeRangeProvider: class {
    func timeRangeAt(startValue: CGFloat, endValue: CGFloat) -> CMTimeRange
    func timeLineView() -> UIView
}

class TimeRangePickerView: UIView {

    weak var timeRangeProvider: TimeRangeProvider? {
        didSet {
            updateTimeLineView()
        }
    }
    
    var timeLineView: UIView?
    var rangeView: TimeRangeView!
    
    convenience init(provider: TimeRangeProvider) {
        self.init(frame: CGRect.zero)
        timeRangeProvider = provider
        updateTimeLineView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        rangeView = TimeRangeView()
        addSubview(rangeView)
        
        rangeView.translatesAutoresizingMaskIntoConstraints = false
        rangeView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        rangeView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        rangeView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rangeView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func updateTimeLineView() {
        timeLineView?.removeFromSuperview()
        if let view = timeRangeProvider?.timeLineView() {
            timeLineView = view
            insertSubview(view, at: 0)
            
            view.translatesAutoresizingMaskIntoConstraints = false
            view.leftAnchor.constraint(equalTo: leftAnchor, constant: rangeView.earWidth).isActive = true
            view.rightAnchor.constraint(equalTo: rightAnchor, constant: -rangeView.earWidth).isActive = true
            view.topAnchor.constraint(equalTo: topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }
    
}

class TimeRangeView: UIView {
    
    private(set) var leftEarImageView: UIImageView!
    private(set) var rightEarImageView: UIImageView!
    private(set) var coverImageView: UIImageView!
    
    var earWidth: CGFloat = 12
    var minmumValue: CGFloat = 0.05
    
    // Current range value, the value is super view's width percent
    private(set) var startValue: CGFloat = 0
    private(set) var endValue: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit()  {
        backgroundColor = UIColor.clear
        
        coverImageView = UIImageView()
        coverImageView.backgroundColor = UIColor.blue.withAlphaComponent(0.3)
        addSubview(coverImageView)
        
        leftEarImageView = EnlargeImageView()
        leftEarImageView.backgroundColor = UIColor.purple
        leftEarImageView.isUserInteractionEnabled = true
        addSubview(leftEarImageView)
        
        rightEarImageView = EnlargeImageView()
        rightEarImageView.backgroundColor = UIColor.purple
        rightEarImageView.isUserInteractionEnabled = true
        addSubview(rightEarImageView)
        
        let leftPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panEarAction(_:)))
        leftEarImageView.addGestureRecognizer(leftPanGesture)
        
        let rightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(panEarAction(_:)))
        rightEarImageView.addGestureRecognizer(rightPanGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let valueWidth = frame.width - earWidth * 2
        
        leftEarImageView.frame = {
            var rect = CGRect.zero
            rect.origin.x = startValue * valueWidth
            rect.size.width = earWidth
            rect.size.height = frame.height
            return rect
        }()
        rightEarImageView.frame = {
            var rect = CGRect.zero
            rect.origin.x = endValue * valueWidth + earWidth
            rect.size.width = earWidth
            rect.size.height = frame.height
            return rect
        }()
        coverImageView.frame = {
            var rect = CGRect.zero
            rect.origin.x = leftEarImageView.frame.maxX
            rect.size.width = rightEarImageView.frame.minX - leftEarImageView.frame.maxX
            rect.size.height = frame.height
            return rect
        }()
    }
    
    @objc private func panEarAction(_ gesture: UIPanGestureRecognizer) {
        let valueWidth = frame.width - earWidth * 2
        
        let translation = gesture.translation(in: gesture.view)
        let percent = translation.x / valueWidth
        if gesture.view == leftEarImageView {
            startValue = min(endValue, max(0.0, startValue + percent))
        } else {
            endValue = min(1.0, max(startValue, endValue + percent))
        }
        layoutSubviews()
        
        gesture.setTranslation(CGPoint.zero, in: gesture.view)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view == self || view == coverImageView {
            return nil
        }
        
        return view
    }
    
}
