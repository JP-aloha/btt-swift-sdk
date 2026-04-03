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
            
            if let sendActionPair = swizzleMethod(UIApplication.self, original: #selector(UIApplication.sendAction(_:to:from:for:)), swizzled: #selector(UIApplication.swizzled_sendAction(_:to:from:for:))) {
                swizzledPairs.append(sendActionPair)
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
    
    func isSwiftUIScreen(_ vc: UIViewController) -> Bool {
        return String(reflecting: type(of: vc)).contains("SwiftUI")
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
        if isAppleClass(self) && !isSwiftUIScreen(self){
            return false
        }
        
        // Ignore spacific controllers to ignore Noise
        // Ignore specific noise-causing view controllers (custom-defined list)
        // These are common system-related view controllers that are not relevant for tracking.
        let excludedClasses: [String] = [
            //"UIHostingController",             // SwiftUI hosting controller
            "UIInputWindowController",         // Handles keyboard input
            "UIEditingOverlayViewController",  // Overlay for text editing
            //"NavigationStackHostingController",// SwiftUI navigation stack
            "UIPredictionViewController",      // Predictive typing view
            "UIPlaceholderPredictiveViewController",  // Placeholder for predictions
            "UlKeyboardMediaServiceRemoteViewController",
            "UISystemKeyboardDockController",
            "UICompatibilityInputViewController",
            "UIMultiscriptCandidateViewController",
            "_UICursorAccessoryViewController",
            "UISystemInputAssistantViewController"
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
            if isSwiftUIScreen(self) {
               /* let screenName = getCurrentScreenName()
                if !screenName.isEmpty {
                    print("SwiftUI View---viewDidLoad---\(String(describing: self))------\(screenName)")
                }*/
            } else {
                BlueTriangle.screenTracker?.loadStarted(String(describing: self), "\(type(of: self))",  pageTitle())
                BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidLoad, className: "\(type(of: self))"))
            }
        }

        viewDidLoad_Tracker()
    }
    
    @objc dynamic func viewWillAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            if isSwiftUIScreen(self) {
               /* let screenName = getCurrentScreenName()
                if !screenName.isEmpty {
                    print("SwiftUI View---viewWillAppear---\(String(describing: self))------\(screenName)")
                }*/
            } else {
                BlueTriangle.screenTracker?.loadFinish(String(describing: self),"\(type(of: self))", pageTitle())
                BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewWillAppear, className: "\(type(of: self))"))
            }
        }

        viewWillAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidAppear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            if isSwiftUIScreen(self) {
                let screenName = getCurrentScreenName(self)
                if !screenName.isEmpty && screenName != UIViewController.lastTrackedScreenName {
                    UIViewController.lastTrackedScreenName = screenName
                    print("SwiftUI View---viewDidAppear---\(String(describing: self))------\(screenName)")
                }
            } else {
                BlueTriangle.screenTracker?.viewStart(String(describing: self), "\(type(of: self))", pageTitle())
                BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidAppear, className: "\(type(of: self))"))
            }
        }
        viewDidAppear_Tracker(animated)
    }
    
    @objc dynamic func viewDidDisappear_Tracker(_ animated: Bool) {
        if shouldTrackScreen(){
            if isSwiftUIScreen(self) {
               /* let screenName = getCurrentScreenName()
                if !screenName.isEmpty {
                    print("SwiftUI View---viewDidDisappear---\(String(describing: self))------\(screenName)")
                }*/
            } else {
                BlueTriangle.screenTracker?.viewingEnd(String(describing: self), "\(type(of: self))", pageTitle())
                BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.viewDidDisappear, className: "\(type(of: self))"))
            }
        }

        viewDidDisappear_Tracker(animated)
    }
    
    func pageTitle() -> String {
        let currentTitle = self.navigationItem.title ?? ""
        return currentTitle
    }
}

extension UIViewController {
    
    private static var lastTrackedScreenName: String = ""
    
    // --------------------------
    func getCurrentScreenName(_ vc: UIViewController) -> String {
         /*guard let vc = UIApplication.shared.topViewController() else {
             return ""
         }*/
        let name = resolveScreenName(vc: vc)
        let screenName = getCurrentScreenName_v2(self)
                
        print("SwiftUI View --- Extract --- \(name) ----Name-- \(screenName)")
         
         if name.contains("RootModifier")  {
             return ""
         }
         return name
     }
     
     // MARK: - MAIN RESOLVER

     private func resolveScreenName(vc: UIViewController) -> String {
         
         // 1. TAB NAME (FIXED)
         if let tab = getTabBarTitle() {
             return tab
         }
         
         // 2. SwiftUI navigationTitle
         if let title = getSwiftUITitle(from: vc) {
             return title
         }
         
         // 3. Visible text fallback
         if let text = findVisibleText(in: vc.view) {
             return text
         }
         
         // 4. Accessibility
         if let id = vc.view.accessibilityIdentifier, !id.isEmpty {
             return id
         }
         
         // 5. SwiftUI type fallback
         let raw = String(describing: type(of: vc))
         if raw.contains("UIHostingController") {
             return cleanSwiftUIName(raw)
         }
         
         return raw
     }

     // MARK: - TAB BAR FIX
     private func getTabBarTitle() -> String? {
         
         guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first else {
             return nil
         }
         
         if let tabBarController = findTabBarController(from: window.rootViewController) {
             
             let index = tabBarController.selectedIndex
             
             if let items = tabBarController.tabBar.items,
                index < items.count {
                 
                 let item = items[index]
                 
                 if let title = item.title, !title.isEmpty {
                     return title
                 }
                 
                 if let label = item.accessibilityLabel {
                     return label
                 }
             }
         }
         
         return nil
     }

     // MARK: - FIND TAB BAR

     private func findTabBarController(from vc: UIViewController?) -> UITabBarController? {
         
         guard let vc = vc else { return nil }
         
         if let tab = vc as? UITabBarController {
             return tab
         }
         
         if let nav = vc as? UINavigationController {
             return findTabBarController(from: nav.visibleViewController)
         }
         
         if let presented = vc.presentedViewController {
             return findTabBarController(from: presented)
         }
         
         for child in vc.children {
             if let found = findTabBarController(from: child) {
                 return found
             }
         }
         
         return nil
     }

     // MARK: - SwiftUI Title

     private func getSwiftUITitle(from vc: UIViewController) -> String? {
         
         if let title = vc.navigationItem.title, !title.isEmpty {
             return title
         }
         
         if let title = vc.navigationController?.navigationBar.topItem?.title,
            !title.isEmpty {
             return title
         }
         
         if let presented = vc.presentedViewController {
             return getSwiftUITitle(from: presented)
         }
         
         return nil
     }

     private func findVisibleText(in view: UIView) -> String? {
         
         if let text = extractText(from: view) {
             return text
         }
         
         let label = view.accessibilityLabel
         let id = view.accessibilityIdentifier
         let large = view.largeContentTitle
         
         print("#: \(label) ------ \(id) ----- \(large)")
         
         for subview in view.subviews {
             if let found = findVisibleText(in: subview) {
                 return found
             }
         }
         
         return nil
     }

     private func extractText(from view: UIView) -> String? {
         
         // 2. Label
         if let label = view as? UILabel,
            let text = label.text,
            !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             return text
         }
         
         // 2. Button
         if let button = view as? UIButton,
            let text = button.title(for: .normal),
            !text.isEmpty {
             return text
         }
         
         // 3. Accessibility
         if let acc = view.accessibilityLabel,
            !acc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
             return acc
         }
         
         // 4. Deep fallback (SwiftUI internal text)
         let mirror = Mirror(reflecting: view)
         for child in mirror.children {
             if let value = child.value as? String,
                !value.isEmpty {
                 return value
             }
         }
         
         return nil
     }
     
     
     private func cleanSwiftUIName(_ name: String) -> String {
         
         guard let start = name.firstIndex(of: "<"),
               let end = name.lastIndex(of: ">") else {
             return name
         }
         
         var extracted = String(name[name.index(after: start)..<end])
         
         let patterns = [
             "ModifiedContent<",
             "AnyView",
             "TupleView<",
             "NavigationStack<",
             "_ConditionalContent<"
         ]
         
         for p in patterns {
             extracted = extracted.replacingOccurrences(of: p, with: "")
         }
         
         extracted = extracted
             .replacingOccurrences(of: "<", with: "")
             .replacingOccurrences(of: ">", with: "")
         
         return extracted.components(separatedBy: ".").last ?? extracted
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

extension UIViewController {
    
    private static var lastTrackedScreenName_v2: String = ""

    // MARK: - Public Entry Point
    func getCurrentScreenName_v2(_ vc: UIViewController) -> String {
        let name = resolveScreenName_v2(vc: vc)
        if name.contains("RootModifier") { return "" }
        return name
    }

    // MARK: - Main Resolver
    private func resolveScreenName_v2(vc: UIViewController) -> String {

        let typeName = String(describing: type(of: vc))

        // 1. ✅ SwiftUI HostingController — deep mirror
        if typeName.contains("HostingController") {
            if let name = extractSwiftUIName_v2(from: vc), !name.isEmpty {
                return name
            }
        }

        // 2. ✅ Check presented VC (Sheet/Modal)
        if let presented = vc.presentedViewController {
            let presentedType = String(describing: type(of: presented))
            if presentedType.contains("HostingController") {
                if let name = extractSwiftUIName_v2(from: presented), !name.isEmpty {
                    return name
                }
            }
        }

        // 3. Tab bar title
        if let tab = getTabBarTitle_v2() { return tab }

        // 4. Navigation title
        if let title = getSwiftUITitle_v2(from: vc) { return title }

        // 5. ✅ Scan view labels / accessibility IDs
        if let label = scanViewHierarchyLabel_v2(in: vc.view) { return label }

        // 6. Accessibility ID
        if let id = vc.view.accessibilityIdentifier, !id.isEmpty { return id }

        // 7. Fallback
        return cleanSwiftUIName_v2(typeName)
    }

    // MARK: - Deep Mirror Unwrap
    private func extractSwiftUIName_v2(from vc: UIViewController) -> String? {

        guard let rootView = mirrorChild_v2(of: vc, labels: ["rootView"]) else {
            return nil
        }

        let rootTypeName = String(describing: type(of: rootView))
        print("🔍 [v2] L1 rootView: \(rootTypeName)")

        if !rootTypeName.contains("AnyView") {
            return unwrapFinalName_v2(from: rootView)
        }

        // Layer 2 — AnyView storage
        let storage = mirrorChild_v2(of: rootView, labels: [
            "storage", "box", "value"
        ]) ?? Mirror(reflecting: rootView).children.first?.value

        guard let storage = storage else {
            return unwrapFinalName_v2(from: rootView)
        }

        let storageTypeName = String(describing: type(of: storage))
        print("🔍 [v2] L2 storage: \(storageTypeName)")

        // Layer 3 — real view
        let realView = mirrorChild_v2(of: storage, labels: [
            "view", "content", "base"
        ]) ?? Mirror(reflecting: storage).children.first?.value

        guard let realView = realView else {
            return unwrapFinalName_v2(from: storage)
        }

        let realTypeName = String(describing: type(of: realView))
        print("🔍 [v2] L3 realView: \(realTypeName)")

        return unwrapFinalName_v2(from: realView)
    }

    // MARK: - Mirror Child by Label
    private func mirrorChild_v2(of object: Any, labels: [String]) -> Any? {
        let mirror = Mirror(reflecting: object)
        for label in labels {
            if let child = mirror.children
                .first(where: { $0.label == label })?.value {
                return child
            }
        }
        return nil
    }

    // MARK: - Unwrap Wrappers → Real View Name
    private func unwrapFinalName_v2(from view: Any, depth: Int = 0) -> String? {

        guard depth < 15 else { return nil }

        let typeName = String(describing: type(of: view))

        let wrappers = [
            "ModifiedContent",
            "AnyView",
            "TupleView",
            "NavigationStack",
            "Group",
            "Optional",
            "RootModifier",
            "_ConditionalContent",
            "BackgroundModifier",
            "PaddingLayout",
            "EnvironmentKeyWritingModifier"
        ]

        let isWrapper = wrappers.contains(where: { typeName.contains($0) })

        if !isWrapper {
            let name = typeName
                .components(separatedBy: "<").first?
                .components(separatedBy: ".").last ?? typeName

            let internalPrefixes = ["_", "Rendering", "Animation", "Gesture"]
            if !internalPrefixes.contains(where: { name.hasPrefix($0) }) {
                print("✅ [v2] Found: \(name)")
                return name
            }
        }

        let mirror = Mirror(reflecting: view)
        for child in mirror.children {
            if let found = unwrapFinalName_v2(from: child.value, depth: depth + 1) {
                return found
            }
        }

        return nil
    }

    // MARK: - ✅ Scan UIView Hierarchy for Labels (Sheet fallback)
    // Finds UILabel or accessibilityLabel in view tree
    private func scanViewHierarchyLabel_v2(in view: UIView, depth: Int = 0) -> String? {

        guard depth < 10 else { return nil }

        // ✅ Check accessibilityIdentifier first
        if let id = view.accessibilityIdentifier,
           !id.isEmpty,
           !id.hasPrefix("fld_"),    // skip text fields
           !id.hasPrefix("btn_") {   // skip buttons
            return id
        }

        // ✅ Check UILabel — find large title text
        if let label = view as? UILabel,
           let text = label.text,
           !text.isEmpty,
           label.font.pointSize >= 20 {   // only large titles
            return text
        }

        for subview in view.subviews {
            if let found = scanViewHierarchyLabel_v2(in: subview, depth: depth + 1) {
                return found
            }
        }

        return nil
    }

    // MARK: - Full Debug
    func debugMirrorLayers_v2(of vc: UIViewController) {
        print("\n========= MIRROR DEBUG v2 =========")
        print("VC: \(type(of: vc))")

        let m1 = Mirror(reflecting: vc)
        print("\n[L1] HostingController children:")
        m1.children.forEach {
            print("  label: '\($0.label ?? "nil")' | type: \(type(of: $0.value))")
        }

        guard let rootView = m1.children
            .first(where: { $0.label == "rootView" })?.value else {
            print("❌ rootView not found"); return
        }
        print("\n[L2] rootView (\(type(of: rootView))) children:")
        let m2 = Mirror(reflecting: rootView)
        m2.children.forEach {
            print("  label: '\($0.label ?? "nil")' | type: \(type(of: $0.value))")
        }

        guard let storage = m2.children.first?.value else {
            print("❌ storage not found"); return
        }
        print("\n[L3] storage (\(type(of: storage))) children:")
        let m3 = Mirror(reflecting: storage)
        m3.children.forEach {
            print("  label: '\($0.label ?? "nil")' | type: \(type(of: $0.value))")
        }

        guard let realView = m3.children.first?.value else {
            print("❌ realView not found"); return
        }
        print("\n[L4] realView (\(type(of: realView))) children:")
        Mirror(reflecting: realView).children.forEach {
            print("  label: '\($0.label ?? "nil")' | type: \(type(of: $0.value))")
        }

        print("\n✅ Final type: \(type(of: realView))")
        print("===================================\n")
    }

    // MARK: - Tab Bar Title
    private func getTabBarTitle_v2() -> String? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let tab = findTabBarController_v2(from: window.rootViewController)
        else { return nil }
        let index = tab.selectedIndex
        guard let items = tab.tabBar.items, index < items.count else { return nil }
        return items[index].title ?? items[index].accessibilityLabel
    }

    private func findTabBarController_v2(from vc: UIViewController?) -> UITabBarController? {
        guard let vc = vc else { return nil }
        if let tab = vc as? UITabBarController { return tab }
        if let nav = vc as? UINavigationController {
            return findTabBarController_v2(from: nav.visibleViewController)
        }
        if let presented = vc.presentedViewController {
            return findTabBarController_v2(from: presented)
        }
        for child in vc.children {
            if let found = findTabBarController_v2(from: child) { return found }
        }
        return nil
    }

    // MARK: - Navigation Title
    private func getSwiftUITitle_v2(from vc: UIViewController) -> String? {
        if let title = vc.navigationItem.title, !title.isEmpty { return title }
        if let title = vc.navigationController?.navigationBar.topItem?.title,
           !title.isEmpty { return title }
        if let presented = vc.presentedViewController {
            return getSwiftUITitle_v2(from: presented)
        }
        return nil
    }

    // MARK: - Clean Fallback
    private func cleanSwiftUIName_v2(_ name: String) -> String {
        guard let start = name.firstIndex(of: "<"),
              let end   = name.lastIndex(of: ">") else { return name }
        var extracted = String(name[name.index(after: start)..<end])
        ["ModifiedContent<", "AnyView", "TupleView<",
         "NavigationStack<", "_ConditionalContent<"].forEach {
            extracted = extracted.replacingOccurrences(of: $0, with: "")
        }
        return extracted
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .components(separatedBy: ".").last ?? extracted
    }
}

#endif
