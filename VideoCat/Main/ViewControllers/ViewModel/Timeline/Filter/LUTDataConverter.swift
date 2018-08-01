//
//  LUTDataConverter.swift
//  VideoCat
//
//  Created by Vito on 2018/7/16.
//  Copyright © 2018 Vito. All rights reserved.
//

import CoreGraphics
import UIKit
import CoreImage
import VFCabbage

class LUTDataConverter {
    
    var intensity: Float = 1.0 {
        didSet {
            needReloadCubeData = true
        }
    }
    fileprivate var needReloadCubeData = true
    
    var lutImage: UIImage {
        didSet {
            loadLutImageBytes()
        }
    }
    init(image: UIImage) {
        self.lutImage = image
        loadLutImageBytes()
    }
    
    fileprivate lazy var originalBitmap: [UInt8] = {
        let image = UIImage(named: "original_lut")
        if let cgimage = image?.cgImage {
            return cgimage.getBytes()
        }
        return []
    }()
    fileprivate var lutBitmap: [UInt8] = []
    fileprivate var cachedFilter: CIFilter?
    
    func filter() -> CIFilter? {
        if needReloadCubeData {
            let size = 64
            if let colorCubeData = generateColorCubeData() {
                let filter = CIFilter(name: "CIColorCube")
                filter?.setValue(colorCubeData, forKey: "inputCubeData")
                filter?.setValue(size, forKey: "inputCubeDimension")
                cachedFilter = filter
            } else {
                cachedFilter = nil
            }
            needReloadCubeData = false
        }
        
        return cachedFilter
    }
    
    fileprivate func loadLutImageBytes() {
        if let lutBitmap = lutImage.cgImage?.getBytes() {
            self.lutBitmap = lutBitmap
            needReloadCubeData = true
        }
    }
    
    fileprivate func generateColorCubeData() -> NSData? {
        guard let lutCGImage = lutImage.cgImage else {
            return nil
        }
        let n = 64
        let width = lutCGImage.width
        let height = lutCGImage.height
        let rowNum = height / n;
        let columnNum = width / n;
        if ((width % n != 0) || (height % n != 0) || (rowNum * columnNum != n)) {
            Log.warning("Invalid colorLUT")
            return nil
        }
        if originalBitmap.count != lutBitmap.count {
            Log.warning("Original colorLUT can't apply to targeted colorLut")
            return nil
        }
        
        let size = n * n * n * MemoryLayout<Float>.size * 4;
        let data = UnsafeMutablePointer<Float>.allocate(capacity: size)
        
        var bitmapOffest: Int = 0;
        var z: Int = 0;
        for _ in 0..<rowNum {
            for y in 0..<n {
                let tmp = z
                for _ in 0..<columnNum {
                    for x in 0..<n {
                        var r: Float, g: Float, b: Float, a: Float
                        r = Float(lutBitmap[bitmapOffest])
                        g = Float(lutBitmap[bitmapOffest + 1])
                        b = Float(lutBitmap[bitmapOffest + 2])
                        a = Float(lutBitmap[bitmapOffest + 3])
                        if (intensity != 1) {
                            let or = Float(originalBitmap[bitmapOffest])
                            let og = Float(originalBitmap[bitmapOffest + 1])
                            let ob = Float(originalBitmap[bitmapOffest + 2])
                            let oa = Float(originalBitmap[bitmapOffest + 3])
                            r = or + (r - or) * intensity
                            g = og + (g - og) * intensity
                            b = ob + (b - ob) * intensity
                            a = oa + (a - oa) * intensity
                        }
                        
                        let dataOffset = (z*n*n + y*n + x) * 4
                        
                        data[dataOffset] = r / 255.0
                        data[dataOffset + 1] = g / 255.0
                        data[dataOffset + 2] = b / 255.0
                        data[dataOffset + 3] = a / 255.0
                        
                        bitmapOffest += 4
                    }
                    z += 1
                }
                z = tmp
            }
            z += columnNum
        }
        return NSData.init(bytesNoCopy: data, length: size)
    }
    
}

extension CGImage {
    func getBytes() -> [UInt8] {
        let bitsPerComponent = 8
        let bytesPerRow = width * 4
        let totalBytes = height * bytesPerRow
        
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelValues = [UInt8](repeating: 0, count: totalBytes)
        
        let contextRef = CGContext(data: &pixelValues, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        contextRef?.draw(self, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
        
        return pixelValues
    }
}
