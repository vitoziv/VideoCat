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
    
    private(set) var timeLineView: UIView?
    private(set) var rangeView: TimeRangeView!
    
    var isContinuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
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
        rangeView.addTarget(self, action: #selector(rangeViewValueChanged(_:)), for: .valueChanged)
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
    
    @objc private func rangeViewValueChanged(_ rangeView: TimeRangeView) {
        
    }
    
}

class TimeRangeView: UIControl {
    
    private(set) var leftEarImageView: UIImageView!
    private(set) var rightEarImageView: UIImageView!
    private(set) var coverImageView: UIImageView!
    
    var earWidth: CGFloat = 12
    var minmumValue: CGFloat = 0.05 {
        didSet {
            minmumValue = min(1.0, max(0.0, minmumValue))
            if endValue - startValue > minmumValue {
                let expectEndValue = startValue + minmumValue
                if expectEndValue > 1 {
                    endValue = 1
                    startValue = 1 - minmumValue
                } else {
                    endValue = expectEndValue
                }
            }
            layoutSubviews()
        }
        
    }
    
    var isContinuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
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
        endValue = startValue + minmumValue
        
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
    
    private var currentStartValue: CGFloat = 0
    private var currentEndValue: CGFloat = 0
    @objc private func panEarAction(_ gesture: UIPanGestureRecognizer) {
        let valueWidth = frame.width - earWidth * 2
        
        let translation = gesture.translation(in: gesture.view)
        if gesture.state == .began {
            currentStartValue = startValue
            currentEndValue = endValue
            sendActions(for: .touchDown)
        }
        
        let percent = translation.x  / valueWidth
        if gesture.view == leftEarImageView {
            startValue = min(endValue - minmumValue, max(0.0, currentStartValue + percent))
        } else {
            endValue = min(1.0, max(startValue + minmumValue, currentEndValue + percent))
        }
        layoutSubviews()
        
        if isContinuous {
            sendActions(for: .valueChanged)
        }
        
        if gesture.state == .ended {
            currentStartValue = 0
            currentEndValue = 0
            
            if !isContinuous {
                sendActions(for: .valueChanged)
            }
            
            let locationOfTouch = gesture.location(in: gesture.view)
            if let view = gesture.view, view.bounds.contains(locationOfTouch) {
                sendActions(for: .touchUpInside)
            } else {
                sendActions(for: .touchUpOutside)
            }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        
        if view == self || view == coverImageView {
            return nil
        }
        
        return view
    }
    
}
