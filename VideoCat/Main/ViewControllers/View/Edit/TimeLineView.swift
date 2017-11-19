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
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.backgroundColor = UIColor.purple
        
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
    }
    
    // MARK: - Data
    
    func append(asset: AVAsset) {
        // TODO: 添加到当前时间点，最接近的地方。
        // 1. 如果没有 asset，直接添加
        // 2. 如果当前时间线压在一个 asset 上，判断时间线在 asset 的偏左边还是偏右边，然后放到最近的位置
        let videoRangeView = VideoRangeView()
        videoRangeView.videoContentView.widthPerSecond = 10
        contentView.addSubview(videoRangeView)
        videoRangeView.configure(asset: asset)
        
        videoRangeView.translatesAutoresizingMaskIntoConstraints = false
        videoRangeView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        videoRangeView.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        videoRangeView.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        videoRangeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    
}
