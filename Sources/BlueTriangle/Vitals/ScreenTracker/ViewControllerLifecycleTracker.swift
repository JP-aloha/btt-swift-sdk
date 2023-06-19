//
//  ViewControllerLifecycleTracker.swift
//  
//
//  Created by Ashok Singh on 13/06/23.
//

#if canImport(UIKit)
import Foundation
import UIKit

fileprivate func swizzleMethod(_ `class`: AnyClass, _ original: Selector, _ swizzled: Selector) {
    
    if let original = class_getInstanceMethod(`class`, original), let swizzled = class_getInstanceMethod(`class`, swizzled) {
        method_exchangeImplementations(original, swizzled)
    }
    else{print("failed to swizzle: \(`class`.self), '\(original)', '\(swizzled)'")}
}

extension UIViewController{
   
    static func setUp(){
        
        // So that It applies to all UIViewController childs
        if self != UIViewController.self {
            return
        }
        
        let _: () = {
         
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidLoad), #selector(UIViewController.viewDidLoad_Tracker))
            
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewWillAppear(_:)), #selector(UIViewController.viewWillAppear_Tracker(_:)))
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewWillDisappear(_:)), #selector(UIViewController.viewWillDisappear_Tracker(_:)))
            
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.viewDidAppear_Tracker(_:)))
            swizzleMethod(UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)), #selector(UIViewController.viewDidDisappear_Tracker(_:)))
            
            swizzleMethod(UIViewController.self, #selector(UIViewController.loadView), #selector(UIViewController.loadView_Tracker))
            
        }()
    }
    
    // background, forground, active, inactive,
    //----------------------------------------------------//
    
    @objc dynamic func viewDidLoad_Tracker() {
        if !self.isKind(of: UINavigationController.self){
            print( "viewDidLoad: \(type(of: self))")
            BTTScreenLifecycleTracker.shared.loadStarted(String(describing: self), "\(type(of: self))")
        }
        viewDidLoad_Tracker()
    }
    
    @objc dynamic func viewWillAppear_Tracker(_ animated: Bool) {
        if !self.isKind(of: UINavigationController.self){
            print( "viewWillAppear: \(type(of: self))")
            BTTScreenLifecycleTracker.shared.loadFinish(String(describing: self), "\(type(of: self))")
        }
        viewWillAppear_Tracker(animated)
    }
    
    @objc dynamic func viewWillDisappear_Tracker(_ animated: Bool) {
        viewWillDisappear_Tracker(animated)
    }
                                    
    @objc dynamic func viewDidAppear_Tracker(_ animated: Bool) {
        if !self.isKind(of: UINavigationController.self){
            print( "viewDidAppear: \(type(of: self))")
            BTTScreenLifecycleTracker.shared.viewStart(String(describing: self), "\(type(of: self))")
        }
        viewDidAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidDisappear_Tracker(_ animated: Bool) {
        if !self.isKind(of: UINavigationController.self){
            print( "viewDidDisappear: \(type(of: self))")
            BTTScreenLifecycleTracker.shared.viewingEnd(String(describing: self), "\(type(of: self))")
        }
        viewDidDisappear_Tracker(animated)
    }
    
    @objc dynamic func loadView_Tracker() {
        loadView_Tracker()
    }
}

#endif
