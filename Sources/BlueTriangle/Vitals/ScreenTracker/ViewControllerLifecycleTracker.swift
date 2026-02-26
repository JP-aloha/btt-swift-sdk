//
//  ViewControllerLifecycleTracker.swift
//
//
//  Created by JP on 13/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
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

extension UIApplication {
    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if let touches = event.allTouches {
            for touch in touches where touch.phase == .began {
                BlueTriangle.groupTimer.setLastAction(Date())
            }
        }
        swizzled_sendEvent(event)
    }
}

extension UIViewController{
    
    private static var isSwizzled = false
    private static var swizzledPairs: [(Method, Method)] = []
    private static var lock = NSLock()
    
    static func setUp() {
        lock.sync {
            guard !isSwizzled else { return }
            
            if let didLoadPair = swizzleMethod(UIViewController.self, original: #selector(viewDidLoad), swizzled: #selector(viewDidLoad_Tracker)) {
                swizzledPairs.append(didLoadPair)
            }
            if let willAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewWillAppear(_:)), swizzled: #selector(viewWillAppear_Tracker(_:))) {
                swizzledPairs.append(willAppearPair)
            }
            if let didAppearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidAppear(_:)), swizzled: #selector(viewDidAppear_Tracker(_:))) {
                swizzledPairs.append(didAppearPair)
            }
            if let didDisappearPair = swizzleMethod(UIViewController.self, original: #selector(viewDidDisappear(_:)), swizzled: #selector(viewDidDisappear_Tracker(_:))) {
                swizzledPairs.append(didDisappearPair)
            }
            
            if let sendEventPair = swizzleMethod(UIApplication.self, original: #selector(UIApplication.sendEvent(_:)), swizzled: #selector(UIApplication.swizzled_sendEvent(_:))) {
                swizzledPairs.append(sendEventPair)
            }
            
            isSwizzled = true
            BlueTriangle.screenTracker?.logger?.debug("View Screen Tracker: setup completed.")
        }
    }
    
    static func removeSetUp() {
        lock.sync {
            guard isSwizzled else { return }
            
            for (original, swizzled) in swizzledPairs {
                method_exchangeImplementations(swizzled, original)
            }
            
            swizzledPairs.removeAll()
            isSwizzled = false
            BlueTriangle.screenTracker?.logger?.debug("View Screen Tracker: setup removed.")
        }
    }
    
    /// Checks if the given object belongs to an Apple framework class.
    /// - Parameter object: The object to be checked.
    /// - Returns: `true` if the object's class is defined within an Apple framework; otherwise, `false`.
    private func isAppleClass(_ object: AnyObject) -> Bool {
        let objectBundle = Bundle(for: type(of: object))
        return objectBundle.bundleIdentifier?.starts(with: "com.apple") ?? false
    }
    
    /// Determines whether the current view controller should be tracked for analytics or other purposes.
    /// - Returns: `true` if the view controller is eligible for tracking; otherwise, `false`.
    func shouldTrackScreen() -> Bool{
        
        let bundle = Bundle(for: type(of: self))
           
        // Ignore classes whose names or superclasses start with an underscore
        // These are typically private or internal Apple system classes.
        if bundle != Bundle.main{
            
            let className = "\(type(of: self))"
            
            if className.hasPrefix("_") {
                return false
            }
            
            let superClassName = "\(type(of: self.superclass))"
            
            if superClassName.hasPrefix("_") {
                return false
            }
        }
        
        // Ignore any view controllers that belong to Apple frameworks
        if isAppleClass(self){
            return false
        }
        
        // Ignore spacific controllers to ignore Noise
        // Ignore specific noise-causing view controllers (custom-defined list)
        // These are common system-related view controllers that are not relevant for tracking.
        let excludedClasses: [String] = [
            "UIHostingController",             // SwiftUI hosting controller
            "UIInputWindowController",         // Handles keyboard input
            "UIEditingOverlayViewController",  // Overlay for text editing
            "NavigationStackHostingController",// SwiftUI navigation stack
            "UIPredictionViewController",      // Predictive typing view
            "UIPlaceholderPredictiveViewController",  // Placeholder for predictions
            "UlKeyboardMediaServiceRemoteViewController"
        ]
        
        let selfClassName = "\(type(of: self))"
        for excludedClass in excludedClasses {
            if selfClassName.contains(excludedClass) {
                return false
            }
        }
        
       // Ignore any view controllers explicitly listed in a developer exclusion list or remote config ignore list
        if let sessionData = BlueTriangle.sessionData(), sessionData.ignoreViewControllers.contains(selfClassName) {
            return false
        }
        
        //Ignore container and input view controllers
        // These are typically not standalone screens and are part of navigation or input handling.
        return !(self.isKind(of: UINavigationController.self)       // Navigation controller
                 || self.isKind(of: UITabBarController.self)         // Tab bar controller
                 || self.isKind(of: UISplitViewController.self)      // Split view controller
                 || self.isKind(of: UIPageViewController.self)       // Page view controller
                 || self.isKind(of: UIInputViewController.self)      // Input method controller
                 || self.isKind(of: UIAlertController.self))         // Alert controller
    }
    
    
    @objc dynamic func viewDidLoad_Tracker() {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.loadStarted(String(describing: self), "\(type(of: self))",  pageTitle())
        }
        BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidLoad, className: "\(type(of: self))"))
        viewDidLoad_Tracker()
    }
    
    @objc dynamic func viewWillAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.loadFinish(String(describing: self),"\(type(of: self))", pageTitle())
        }
        BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewWillAppear, className: "\(type(of: self))"))
        viewWillAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.viewStart(String(describing: self), "\(type(of: self))", pageTitle())
        }
        BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidAppear, className: "\(type(of: self))"))
        viewDidAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidDisappear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BlueTriangle.screenTracker?.viewingEnd(String(describing: self), "\(type(of: self))", pageTitle())
        }
        BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidDisappear, className: "\(type(of: self))"))
        viewDidDisappear_Tracker(animated)
    }
    
    func pageTitle() -> String {
        let currentTitle = self.navigationItem.title ?? ""
        return currentTitle
    }
}

extension UIView {
    func superview<T: UIView>(of type: T.Type) -> T? {
        return superview as? T ?? superview?.superview(of: type)
    }

    func superview(ofClassNamed className: String) -> UIView? {
        if NSStringFromClass(type(of: self)).contains(className) {
            return self
        } else {
            return self.superview?.superview(ofClassNamed: className)
        }
    }
}
#endif
