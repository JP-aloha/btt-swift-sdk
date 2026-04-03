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

/*extension UIViewController {
    
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
}*/

extension UIViewController {
    
    private static var lastTrackedScreenName: String = ""
    
    // MARK: - Public Entry Point
    func getCurrentScreenName(_ vc: UIViewController) -> String {
        let name = resolveScreenName(vc: vc)
        print("SwiftUIView Screen Tracked → \(name)")
        if name.contains("RootModifier") { return "" }
        return name
    }
    
    
    private func resolveScreenName(vc: UIViewController) -> String {
        
        let typeName = String(describing: type(of: vc))
        
        // ✅ Catch ALL HostingController variants
        let hostingVariants = [
            "HostingController",        // UIHostingController
            "PresentationHostingController",  // Sheet
            "NavigationStackHostingController" // NavigationStack
        ]
        
        if hostingVariants.contains(where: { typeName.contains($0) }) {
            if let name = extractSwiftUIStructName(from: vc), !name.isEmpty {
                print("✅ Resolved: \(name)")
                return name
            }
        }
        
        // rest of your fallbacks...
        if let tab = getTabBarTitle() { return tab }
        if let title = getSwiftUITitle(from: vc) { return title }
        if let text = findLargeTitleText(in: vc.view) { return text }
        if let id = vc.view.accessibilityIdentifier, !id.isEmpty { return id }
        
        return cleanSwiftUIName(typeName)
    }
    
    private func extractSwiftUIStructName(from vc: UIViewController) -> String? {
        
        let vcTypeName = String(describing: type(of: vc))
        let vcMirror = Mirror(reflecting: vc)
        
        // ✅ Standard HostingController path
        if let rootView = vcMirror.children
            .first(where: { $0.label == "rootView" })?.value {
            let rootTypeName = String(describing: type(of: rootView))
            print("🔍 rootView: \(rootTypeName)")
            return extractFromAnyView(rootView)
        }
        
        // ✅ PresentationHostingController path — no rootView, uses delegate
        if vcTypeName.contains("PresentationHostingController") {
            return extractFromPresentationController(vcMirror)
        }
        
        return nil
    }

    // MARK: - PresentationHostingController → delegate → content → LoginView
    private func extractFromPresentationController(_ vcMirror: Mirror) -> String? {
        
        // Step 1 — get delegate
        guard let delegate = vcMirror.children
            .first(where: { $0.label == "delegate" })?.value else {
            print("❌ No delegate found")
            return nil
        }
        
        print("🔍 delegate type: \(type(of: delegate))")
        
        // Step 2 — unwrap Optional<delegate>
        let delegateMirror = Mirror(reflecting: delegate)
        print("🔍 delegate children:")
        delegateMirror.children.forEach {
            print("   '\($0.label ?? "nil")' → \(type(of: $0.value))")
        }
        
        // Step 3 — find content/view/rootView inside delegate
        let contentLabels = ["content", "view", "rootView", "body", "presentation", "some"]
        
        // Try direct label match
        if let content = delegateMirror.children
            .first(where: { contentLabels.contains($0.label ?? "") })?.value {
            print("🔍 delegate content: \(type(of: content))")
            return extractFromAnyView(content)
        }
        
        // Try unwrap Optional (delegate is Optional<X>)
        if let some = delegateMirror.children.first?.value {
            print("🔍 delegate.some: \(type(of: some))")
            let someMirror = Mirror(reflecting: some)
            print("🔍 delegate.some children:")
            someMirror.children.forEach {
                print("   '\($0.label ?? "nil")' → \(type(of: $0.value))")
            }
            
            // Find content inside unwrapped delegate
            if let content = someMirror.children
                .first(where: { contentLabels.contains($0.label ?? "") })?.value {
                print("🔍 delegate.some content: \(type(of: content))")
                return extractFromAnyView(content)
            }
            
            // Last — try all children recursively
            for child in someMirror.children {
                if let found = unwrapViewName(from: child.value) {
                    return found
                }
            }
        }
        
        return nil
    }

    // MARK: - AnyView → storage → view → RealView
    private func extractFromAnyView(_ rootView: Any) -> String? {
        
        let rootTypeName = String(describing: type(of: rootView))
        
        if !rootTypeName.contains("AnyView") {
            return unwrapViewName(from: rootView)
        }
        
        // L2 — storage inside AnyView
        let anyViewMirror = Mirror(reflecting: rootView)
        let storage = anyViewMirror.children
            .first(where: { ["storage", "box", "value"].contains($0.label ?? "") })?.value
            ?? anyViewMirror.children.first?.value
        
        guard let storage = storage else {
            return unwrapViewName(from: rootView)
        }
        
        print("🔍 AnyView storage: \(type(of: storage))")
        
        // L3 — real view inside storage
        let storageMirror = Mirror(reflecting: storage)
        let realView = storageMirror.children
            .first(where: { ["view", "content", "base"].contains($0.label ?? "") })?.value
            ?? storageMirror.children.first?.value
        
        guard let realView = realView else {
            return unwrapViewName(from: storage)
        }
        
        print("🔍 realView: \(type(of: realView))")
        
        return unwrapViewName(from: realView)
    }

    // MARK: - Unwrap Wrappers → Real View Name
    private func unwrapViewName(from view: Any, depth: Int = 0) -> String? {
        
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
            "SheetBridge",              // ✅ Skip SheetBridge wrapper
            "PresentationBridge",       // ✅ Skip PresentationBridge
            "_ConditionalContent",
            "BackgroundModifier",
            "EnvironmentKeyWritingModifier"
        ]
        
        let isWrapper = wrappers.contains(where: { typeName.contains($0) })
        
        if !isWrapper {
            let name = typeName
                .components(separatedBy: "<").first?
                .components(separatedBy: ".").last ?? typeName
            
            let skip = ["_", "Rendering", "Animation", "Gesture", "Delegate", "Bridge"]
            if !skip.contains(where: { name.hasPrefix($0) || name.hasSuffix($0) }) {
                print("✅ Found: \(name)")
                return name
            }
        }
        
        // Dig deeper
        let mirror = Mirror(reflecting: view)
        for child in mirror.children {
            if let found = unwrapViewName(from: child.value, depth: depth + 1) {
                return found
            }
        }
        
        return nil
    }
    
    // MARK: - ✅ Large Title Text Only (avoids buttons/fields)
    private func findLargeTitleText(in view: UIView, depth: Int = 0) -> String? {
        
        guard depth < 15 else { return nil }
        
        if let label = view as? UILabel,
           let text = label.text,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           label.font.pointSize >= 20 {          // ✅ Only large text = titles
            return text
        }
        
        for subview in view.subviews {
            if let found = findLargeTitleText(in: subview, depth: depth + 1) {
                return found
            }
        }
        
        return nil
    }

    // MARK: - TAB BAR
    private func getTabBarTitle() -> String? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first,
            let tabBarController = findTabBarController(from: window.rootViewController)
        else { return nil }
        
        let index = tabBarController.selectedIndex
        guard let items = tabBarController.tabBar.items,
              index < items.count else { return nil }
        
        let item = items[index]
        return item.title ?? item.accessibilityLabel
    }

    private func findTabBarController(from vc: UIViewController?) -> UITabBarController? {
        guard let vc = vc else { return nil }
        if let tab = vc as? UITabBarController { return tab }
        if let nav = vc as? UINavigationController {
            return findTabBarController(from: nav.visibleViewController)
        }
        if let presented = vc.presentedViewController {
            return findTabBarController(from: presented)
        }
        for child in vc.children {
            if let found = findTabBarController(from: child) { return found }
        }
        return nil
    }

    // MARK: - SwiftUI Navigation Title
    private func getSwiftUITitle(from vc: UIViewController) -> String? {
        if let title = vc.navigationItem.title, !title.isEmpty { return title }
        if let title = vc.navigationController?.navigationBar.topItem?.title,
           !title.isEmpty { return title }
        if let presented = vc.presentedViewController {
            return getSwiftUITitle(from: presented)
        }
        return nil
    }

    // MARK: - Your Existing findVisibleText (kept for reference)
    private func findVisibleText(in view: UIView) -> String? {
        if let text = extractText(from: view) { return text }
        for subview in view.subviews {
            if let found = findVisibleText(in: subview) { return found }
        }
        return nil
    }

    private func extractText(from view: UIView) -> String? {
        if let label = view as? UILabel,
           let text = label.text,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        if let button = view as? UIButton,
           let text = button.title(for: .normal),
           !text.isEmpty {
            return text
        }
        if let acc = view.accessibilityLabel,
           !acc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return acc
        }
        let mirror = Mirror(reflecting: view)
        for child in mirror.children {
            if let value = child.value as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    // MARK: - Clean Type Name Fallback
    private func cleanSwiftUIName(_ name: String) -> String {
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
    
    // MARK: - Debug (keep until stable)
    func debugMirrorLayers(of vc: UIViewController) {
        print("\n========= MIRROR DEBUG =========")
        print("VC: \(type(of: vc))")
        let m1 = Mirror(reflecting: vc)
        print("[L1] children:")
        m1.children.forEach {
            print("  '\($0.label ?? "nil")' → \(type(of: $0.value))")
        }
        guard let rootView = m1.children
            .first(where: { $0.label == "rootView" })?.value else {
            print("❌ No rootView"); return
        }
        let m2 = Mirror(reflecting: rootView)
        print("\n[L2] rootView (\(type(of: rootView))):")
        m2.children.forEach {
            print("  '\($0.label ?? "nil")' → \(type(of: $0.value))")
        }
        guard let storage = m2.children.first?.value else {
            print("❌ No storage"); return
        }
        let m3 = Mirror(reflecting: storage)
        print("\n[L3] storage (\(type(of: storage))):")
        m3.children.forEach {
            print("  '\($0.label ?? "nil")' → \(type(of: $0.value))")
        }
        guard let realView = m3.children.first?.value else {
            print("❌ No realView"); return
        }
        print("\n✅ Final: \(type(of: realView))")
        print("================================\n")
    }
}

extension UIView {
    func superview<T: UIView>(of type: T.Type) -> T? {
        return superview as? T ?? superview?.superview(of: type)
    }
    func superview(ofClassNamed className: String) -> UIView? {
        if NSStringFromClass(type(of: self)).contains(className) { return self }
        return self.superview?.superview(ofClassNamed: className)
    }
}

#endif
