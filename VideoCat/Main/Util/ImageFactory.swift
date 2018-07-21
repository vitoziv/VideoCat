//
//  ImageFactory.swift
//  VideoCat
//
//  Created by Vito on 2018/7/19.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit

extension UIImage {
    
    static func createImage(string: NSAttributedString, size: CGSize, backgroundColor: UIColor) -> UIImage? {
        if size.width == 0 || size.height == 0 || string.string.count == 0 {
            return nil
        }
        let stringBounds = string.boundingRect(with: size, options: [], context: nil)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        let rect = CGRect(origin: .zero, size: size)
        backgroundColor.setFill()
        context?.fill(rect)
        
        let point = CGPoint.init(x: (size.width - stringBounds.size.width) / 2, y: (size.height - stringBounds.size.height) / 2)
        string.draw(at: point)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
