//
//  WaveformView.swift
//  TimeRange
//
//  Created by Vito on 28/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation

class WaveformView: UIView {
    
    override open class var layerClass: Swift.AnyClass {
        return CAShapeLayer.self
    }
    
    var waveformLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    private var pointInfo = [CGPoint]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        waveformLayer.lineWidth = 1
        waveformLayer.fillColor = nil
        waveformLayer.backgroundColor = nil
        waveformLayer.isOpaque = true
        waveformLayer.strokeColor = UIColor.lightGray.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        redraw()
    }
    
    // MARK: - Public
    
    func updateSampleData(data: [Float]) {
        pointInfo.removeAll()
        for (index, point) in data.enumerated() {
            let point = CGPoint(x: CGFloat(index), y: CGFloat(point))
            pointInfo.append(point)
        }
    }
    
    func redraw() {
        let frame = waveformLayer.bounds
        DispatchQueue.global().async {
            let path = self.createPath(with: self.pointInfo, pointCount: self.pointInfo.count, in: frame)
            DispatchQueue.main.async {
                self.waveformLayer.path = path
            }
        }
    }
    
    func createPath(with points: [CGPoint], pointCount: Int, in rect: CGRect) -> CGPath {
        let path = UIBezierPath()
        
        guard pointCount > 0 else {
            return path.cgPath
        }
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        for index in 0..<pointCount {
            var point = points[index]
            path.move(to: point)
            
            point.y = -point.y
            path.addLine(to: point)
        }
        
        let scaleX = rect.width / CGFloat(pointCount - 1)
        let halfHeight = rect.height / 2
        let scaleY = halfHeight
        var transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        transform.ty = halfHeight
        path.apply(transform)
        return path.cgPath
    }
    
    private var currentPath: CGPath?
    func scale(_ scale: CGFloat, end: Bool) {
        if currentPath == nil {
            currentPath = waveformLayer.path
        }
        let currentScale = 1 + (scale - 1) / 10
        
        if let originPath = currentPath {
            let path = UIBezierPath(cgPath: originPath)
            let transform = CGAffineTransform(scaleX: currentScale, y: 1)
            path.apply(transform)
            waveformLayer.path = path.cgPath
        }
        
        if end {
            currentPath = nil
        }
    }
    
}
