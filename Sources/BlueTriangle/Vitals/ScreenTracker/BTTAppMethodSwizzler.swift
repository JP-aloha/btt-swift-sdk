//
//  AppSwizzling.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/05/26.
//

#if os(iOS)
import Foundation
import UIKit
import SwiftUI

fileprivate func swizzleMethod(_ cls: AnyClass, original: Selector, swizzled: Selector) -> (Method, Method)? {
    guard
        let originalMethod = class_getInstanceMethod(cls, original),
        let swizzledMethod = class_getInstanceMethod(cls, swizzled)
    else {
        BlueTriangle.screenTracker?.logger?.error("Swizzling failed: \(cls) \(original) ↔︎ \(swizzled)")
        return nil
    }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
    return (originalMethod, swizzledMethod)
}

internal func setUpAppSwizzling() {
    UIViewController.setUpVcSwizzling()
    UIApplication.setUpActionSwizzling()
}

extension UIApplication {
    private static var lock = NSLock()
    private static var isActionSwizzled = false
    private static var actionPairs: [(Method, Method)] = []
    
    static func setUpActionSwizzling() {
        lock.sync {
            guard !isActionSwizzled, BlueTriangle.configuration.enableGroupingTapDetection else { return }
            
            if let sendEventPair = swizzleMethod(UIApplication.self, original: #selector(UIApplication.sendEvent(_:)), swizzled: #selector(UIApplication.swizzled_sendEvent(_:))) {
                actionPairs.append(sendEventPair)
            }
            
            if let sendActionPair = swizzleMethod(UIApplication.self, original: #selector(UIApplication.sendAction(_:to:from:for:)), swizzled: #selector(UIApplication.swizzled_sendAction(_:to:from:for:))) {
                actionPairs.append(sendActionPair)
            }
            
            isActionSwizzled = true
            BlueTriangle.screenTracker?.logger?.debug("Action Swizzling: setup completed.")
        }
    }
}

extension UIViewController {
    private static var lock = NSLock()
    private static var isVCSwizzled = false
    private static var vcPairs: [(Method, Method)] = []
    
    static func setUpVcSwizzling() {
        lock.sync {
            guard !isVCSwizzled else { return }
            
            if let didLoadPair = swizzleMethod(UIViewController.self, original: #selector(viewDidLoad), swizzled: #selector(viewDidLoad_Tracker)) {
                vcPairs.append(didLoadPair)
            }
            if let willAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewWillAppear(_:)), swizzled: #selector(viewWillAppear_Tracker(_:))) {
                vcPairs.append(willAppearPair)
            }
            if let didAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidAppear(_:)), swizzled: #selector(viewDidAppear_Tracker(_:))) {
                vcPairs.append(didAppearPair)
            }
            if let didDisappearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidDisappear(_:)), swizzled: #selector(viewDidDisappear_Tracker(_:))) {
                vcPairs.append(didDisappearPair)
            }
            
            isVCSwizzled = true
            BlueTriangle.screenTracker?.logger?.debug("View Swizzling: setup completed.")
        }
    }
}
#endif
