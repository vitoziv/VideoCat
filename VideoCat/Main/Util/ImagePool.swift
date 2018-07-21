//
//  ImagePool.swift
//  VideoCat
//
//  Created by Vito on 2018/7/19.
//  Copyright © 2018 Vito. All rights reserved.
//

import UIKit

class ImagePool {
    
    static let current = ImagePool()
    
    private var imageCache: [String: UIImage] = [:]
    
    func defaultPlaceholderImage(size: CGSize) -> UIImage? {
        let key = "\(size)"
        if let image = imageCache[key] {
            return image
        }
        
        let image = createImageViewPlaceHodlerImage(size: size)
        imageCache[key] = image
        
        return image
    }
    
    private func createImageViewPlaceHodlerImage(size: CGSize) -> UIImage? {
        let backgroundColor = UIColor.init(white: 1, alpha: 0.4)
        
        let ParagraphStyle = NSMutableParagraphStyle.init()
        ParagraphStyle.alignment = .center
        let attributes: [NSAttributedStringKey: Any] =
            [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: size.width / 5),
                NSAttributedStringKey.foregroundColor: UIColor.init(white: 0.4, alpha: 1),
                NSAttributedStringKey.paragraphStyle: ParagraphStyle
        ]
        let string = NSMutableAttributedString.init(string: "IMAGE", attributes: attributes)
        
        return UIImage.createImage(string: string, size: size, backgroundColor: backgroundColor)
    }
}
