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
    
    private var pointInfo = PointInfo()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        waveformLayer.lineWidth = 1.0
        waveformLayer.fillColor = nil
        waveformLayer.backgroundColor = nil
        waveformLayer.isOpaque = true
        waveformLayer.strokeColor = UIColor.lightGray.cgColor
    }
    
    func updateSampleData(data: UnsafePointer<Float>, length: Int) {
        pointInfo = PointInfo(pointCount: length)
        for index in 0..<length {
            let point = CGPoint(x: CGFloat(index), y: CGFloat(data[index]))
            pointInfo.points?[index] = point
        }
        pointInfo.points?[0].y = 0
        pointInfo.points?[length - 1].y = 0
    }
    
    func redraw() {
        let frame = waveformLayer.bounds
        guard let points = pointInfo.points else {
            return
        }
        let path = createPath(with: points, pointCount: pointInfo.pointCount, in: frame)
        waveformLayer.path = path
    }
    
    func createPath(with points: UnsafePointer<CGPoint>, pointCount: Int, in rect: CGRect) -> CGPath {
        let path = UIBezierPath()
        
        guard pointCount > 0 else {
            return path.cgPath
        }
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        for index in 0..<pointCount {
            var point = points[index]
            let originX = point.x
            point.x = originX - 0.5
            path.addLine(to: point)
            
            point.x = originX
            point.y = -point.y
            path.addLine(to: point)
        }
        
        let scaleX = rect.width / CGFloat(pointCount)
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
