//
//  EnlargeImageView.swift
//  VideoCat
//
//  Created by Vito on 29/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit

class EnlargeImageView: UIImageView {

    @IBInspectable var topInset: CGFloat = 10
    @IBInspectable var leftInset: CGFloat = 10
    @IBInspectable var rightInset: CGFloat = 10
    @IBInspectable var bottomInset: CGFloat = 10
    
    var enlargeInset: UIEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10) {
        didSet {
            self.topInset = enlargeInset.top
            self.bottomInset = enlargeInset.bottom
            self.leftInset = enlargeInset.left
            self.rightInset = enlargeInset.right
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let x = bounds.origin.x - leftInset
        let y = bounds.origin.y - topInset
        let width = bounds.size.width + rightInset + leftInset
        let height = bounds.size.height + bottomInset + topInset
        let rect = CGRect(x: x, y: y, width: width, height: height)
        if rect.equalTo(bounds) {
            return super.point(inside: point, with: event)
        }
        
        if rect.contains(point) && !isHidden {
            return true
        }
        
        return false
    }
    
}
