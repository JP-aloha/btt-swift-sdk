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

fileprivate func swizzleMethod(_ `class`: AnyClass, _ original: Selector, _ swizzled: Selector) {
    
    if let original = class_getInstanceMethod(`class`, original), let swizzled = class_getInstanceMethod(`class`, swizzled) {
        method_exchangeImplementations(original, swizzled)
    }
    else{
        BTTScreenLifecycleTracker.shared.logger?.error("View Screen Tracker: failed to swizzle: \(`class`.self), '\(original)', '\(swizzled)'")
    }
}

extension UIViewController{
   
    static func setUp(){
    
        let  _ : () = {
            
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidLoad), #selector(UIViewController.viewDidLoad_Tracker))
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)), #selector(UIViewController.viewWillAppear_Tracker(_:)))
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.viewDidAppear_Tracker(_:)))
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)), #selector(UIViewController.viewDidDisappear_Tracker(_:)))
            BTTScreenLifecycleTracker.shared.logger?.debug("View Screen Tracker: setup completed.")
        }()
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
            "UIPlaceholderPredictiveViewController" // Placeholder for predictions
        ]
        
        let selfClassName = "\(type(of: self))"
        for excludedClass in excludedClasses {
            if selfClassName.contains(excludedClass) {
                return false
            }
        }
        
       // Ignore any view controllers explicitly listed in a developer exclusion list or remote config ignore list
        if BlueTriangle.sessionData().ignoreViewControllers.contains(selfClassName) {
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
            BTTScreenLifecycleTracker.shared.loadStarted(String(describing: self), "\(type(of: self))")
        }
        viewDidLoad_Tracker()
    }
    
    @objc dynamic func viewWillAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BTTScreenLifecycleTracker.shared.loadFinish(String(describing: self), "\(type(of: self))")
        }
        viewWillAppear_Tracker(animated)
    }
                                
    @objc dynamic func viewDidAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BTTScreenLifecycleTracker.shared.viewStart(String(describing: self), "\(type(of: self))")
        }
        viewDidAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidDisappear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            BTTScreenLifecycleTracker.shared.viewingEnd(String(describing: self), "\(type(of: self))")
        }
        viewDidDisappear_Tracker(animated)
    }
}

#endif
