//
//  AppDelegate.swift
//  VideoCat
//
//  Created by Vito on 27/08/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import UIKit
import AVFoundation
import VFCabbage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Log.output = [.debug, .error, .warning]
        
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        return true
    }

}

