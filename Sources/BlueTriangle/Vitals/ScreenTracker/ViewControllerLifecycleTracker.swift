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
    
    func shouldTrackScreen() -> Bool{
        
        // Ignore non-main bundle view controllers whose class or superclass is an internal iOS view controller
        
        let bundle = Bundle(for: type(of: self))
                
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
        
        // Ignore spacific controllers to ignore Noise
        let excludedClasses: [String] = [
            "UIHostingController",
            "UIInputWindowController",
            "UIEditingOverlayViewController",
            "NavigationStackHostingController",
            "UIPredictionViewController",
            "UIPlaceholderPredictiveViewController"
        ]
    
        let selfClassName = "\(type(of: self))"
        for excludedClass in excludedClasses {
            if selfClassName.contains(excludedClass) {
                return false
            }
        }
        
        // We are not capturing screen traces for any container or input view controllers.
        return !(self.isKind(of: UINavigationController.self)
                            || self.isKind(of: UINavigationController.self)
                            || self.isKind(of: UITabBarController.self)
                            || self.isKind(of: UISplitViewController.self)
                            || self.isKind(of: UIPageViewController.self)
                            || self.isKind(of: UIInputViewController.self)
                            || self.isKind(of: UIAlertController.self)
                            || self.isKind(of: UIAlertController.self))
        
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
