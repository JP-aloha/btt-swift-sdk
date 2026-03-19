//
//  UIViewController+Utils.swift
//  blue-triangle
//
//  Created by Ashok Singh on 19/03/26.
//

import UIKit
import SwiftUI

extension UIViewController {
    func bt_topmostUserFacingViewController() -> UIViewController {
        // Walk ALL presented VCs including SwiftUI internal ones
        if let presented = presentedViewController {
            return presented.bt_topmostUserFacingViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.bt_topmostUserFacingViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.bt_topmostUserFacingViewController() ?? self
        }
        return self
    }

    func bt_containsVC(_ vc: UIViewController) -> Bool {
        for child in children {
            if child === vc { return true }
            if child.bt_containsVC(vc) { return true }
        }
        if let presented = presentedViewController {
            if presented === vc { return true }
            if presented.bt_containsVC(vc) { return true }
        }
        return false
    }
}
