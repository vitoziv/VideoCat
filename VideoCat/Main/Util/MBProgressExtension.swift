//
//  MBProgressExtension.swift
//  VideoCat
//
//  Created by Vito on 24/09/2017.
//  Copyright © 2017 Vito. All rights reserved.
//

import Foundation
import MBProgressHUD

extension MBProgressHUD {
    
    class func createHud(inView: UIView? = nil) -> MBProgressHUD {
        let view = inView ?? UIApplication.shared.keyWindow!
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.bezelView.color = UIColor.clear
        hud.bezelView.style = .solidColor
        hud.minSize = CGSize(width: 50, height: 36)
        hud.animationType = .fade
        hud.isUserInteractionEnabled = false
        
        return hud
    }
    
    @discardableResult
    class func show(inView: UIView? = nil, hideAfterDelay: TimeInterval? = 2) -> MBProgressHUD {
        let view = inView ?? UIApplication.shared.keyWindow!
        MBProgressHUD.hide(for: view, animated: true)
        
        let hud = createHud(inView: view)
        
        if let delay = hideAfterDelay {
            hud.hide(animated: true, afterDelay: delay)
        }
        
        return hud
    }
    
    @discardableResult
    class func showLoading(inView: UIView? = nil) -> MBProgressHUD {
        let view = inView ?? UIApplication.shared.keyWindow!
        MBProgressHUD.hide(for: view, animated: true)
        
        let hud = createHud(inView: view)
        hud.bezelView.color = UIColor(white: 0, alpha: 0.7)
        hud.contentColor = UIColor.white
        
        return hud
    }
    
    @discardableResult
    class func showProgress(inView: UIView? = nil, hideAfterDelay: TimeInterval? = nil) -> MBProgressHUD {
        let view = inView ?? UIApplication.shared.keyWindow!
        MBProgressHUD.hide(for: view, animated: true)
        
        let hud = createHud(inView: view)
        hud.bezelView.color = UIColor.white
        hud.mode = .determinate
        hud.isUserInteractionEnabled = true
        
        if let delay = hideAfterDelay {
            hud.hide(animated: true, afterDelay: delay)
        }
        
        return hud
    }
    
    @discardableResult
    class func showSuccess(title: String, inView: UIView? = nil, hideAfterDelay: TimeInterval? = 2) -> MBProgressHUD {
        let hud = self.show(inView: inView, hideAfterDelay: hideAfterDelay)
        
        hud.mode = .text
        hud.label.textColor = UIColor.green
        hud.label.text = title
        
        return hud
    }
    
    @discardableResult
    class func showError(title: String, inView: UIView? = nil, hideAfterDelay: TimeInterval? = 2) -> MBProgressHUD {
        let hud = self.show(inView: inView, hideAfterDelay: hideAfterDelay)
        
        hud.mode = .text
        hud.label.textColor = UIColor.red
        hud.label.text = title
        
        return hud
    }
    
    class func dismiss(inView: UIView? = nil, animated: Bool = true) {
        let view = inView ?? UIApplication.shared.keyWindow!
        MBProgressHUD.hide(for: view, animated: animated)
    }
}

extension MBProgressHUD {
    
    @discardableResult
    class func showError(_ error: NSError, inView: UIView? = nil, hideAfterDelay: TimeInterval? = 2) -> MBProgressHUD {
        let errorMessage = error.localizedDescription
        return showError(title: errorMessage, inView: inView, hideAfterDelay: hideAfterDelay)
    }
    
}
