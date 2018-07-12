//
//  UIStyle.swift
//  VideoCat
//
//  Created by Vito on 07/11/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit

extension UIColor {
    static let titleColor = UIColor(white: 0.16, alpha: 1)
    static let contentColor = UIColor(white: 0.86, alpha: 1)
    static let detailColor = UIColor(white: 0.38, alpha: 1)
}

extension UIFont {
    static let titleFont = UIFont(name: "PingFangSC-Semibold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
    static let contentFont = UIFont(name: "PingFangSC-Light", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .light)
    static let detailFont = UIFont(name: "PingFangSC-Light", size: 13) ?? UIFont.systemFont(ofSize: 13, weight: .light)
}
