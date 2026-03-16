import UIKit
import SwiftUI

// MARK: - UIView Associated Object
/*
private var btActionKey: UInt8 = 0

// MARK: - UIView Associated Object

extension UIView {
    var btAction: String? {
        get { objc_getAssociatedObject(self, &btActionKey) as? String }
        set { objc_setAssociatedObject(self, &btActionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - SwiftUI Modifier

public extension View {
    func bttTrackAction(_ action: String) -> some View {
        modifier(BTTrackModifier(action: action))
    }
}

private struct BTTrackModifier: ViewModifier {
    let action: String
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    BTAnchorView(action: action, size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            )
    }
}

// MARK: - UIViewRepresentable
private struct BTAnchorView: UIViewRepresentable {
    let action: String
    let size: CGSize

    func makeUIView(context: Context) -> BTTouchAnchor {
        let view = BTTouchAnchor()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: BTTouchAnchor, context: Context) {
        uiView.action = action
        DispatchQueue.main.async {
            if let superview = uiView.superview {
                uiView.frame = CGRect(origin: .zero, size: superview.bounds.size)
            }
        }
    }
}

// MARK: - Anchor UIView

final class BTTouchAnchor: UIView {
    var action: String = "" {
        didSet { if !action.isEmpty { BTViewRegistry.shared.register(self, action: action) } }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, !action.isEmpty {
            BTViewRegistry.shared.register(self, action: action)
        } else {
            BTViewRegistry.shared.unregister(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !action.isEmpty { BTViewRegistry.shared.register(self, action: action) }
    }
}

// MARK: - Global Registry

final class BTViewRegistry {
    static let shared = BTViewRegistry()
    private init() {}

    private struct Entry {
        weak var view: BTTouchAnchor?
        let action: String
    }

    private var entries: [Entry] = []
    private let lock = NSLock()

    func register(_ view: BTTouchAnchor, action: String) {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
        entries.append(Entry(view: view, action: action))
    }

    func unregister(_ view: BTTouchAnchor) {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
    }

    /*func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil }

        var best: (UIView, String, CGFloat)?
        for entry in entries {
            guard let anchor = entry.view, anchor.window == window else { continue }
            let pointInAnchor = anchor.convert(point, from: window)
            guard anchor.bounds.contains(pointInAnchor) else { continue }
            let area = anchor.bounds.width * anchor.bounds.height
            if best == nil || area < best!.2 {
                best = (anchor, entry.action, area)
            }
        }
        return best.map { ($0.0, $0.1) }
    }*/
    
    func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil }

        var best: (UIView, String, CGFloat)?

        for entry in entries {
            guard let anchor = entry.view, anchor.window == window else { continue }

            let anchorFrameInWindow = anchor.convert(anchor.bounds, to: window)
            print(" anchor action: \(entry.action)")
            print(" anchor frameInWindow: \(anchorFrameInWindow)")
            print(" touch point: \(point)")
            print(" contains: \(anchorFrameInWindow.contains(point))")
            
            guard let hit = window.hitTest(point, with: nil),
                  anchor.isDescendant(of: hit) || hit.isDescendant(of: anchor) else { continue }

            let pointInAnchor = anchor.convert(point, from: window)
            guard anchor.bounds.contains(pointInAnchor) else { continue }

            let area = anchor.bounds.width * anchor.bounds.height

            if best == nil || area < best!.2 {
                best = (anchor, entry.action, area)
            }
        }

        return best.map { ($0.0, $0.1) }
    }
}

// MARK: - UIView Helpers

extension UIView {
    
    /// Walk UP the chain — find the first real actionable target
    ///
    /// Walk UP the chain — find the first real actionable target
    func bt_findActionableTarget() -> UIView? {
        var current: UIView? = self

        while let view = current {

            if view is UIWindow { return nil }

            let className = String(describing: type(of: view))

            guard view.isUserInteractionEnabled,
                  !view.isHidden,
                  view.alpha > 0 else {
                current = view.superview
                continue
            }

            // Skip layout/container views
            let isContainer = view is UIStackView
                || view is UIScrollView
                || className.contains("Hosting")
                || className.contains("Container")
                || className.contains("UITransitionView")
                || className.contains("UILayoutContainerView")

            if isContainer {
                current = view.superview
                continue
            }

            // Positive signals
            if view is UIControl { return view }
            if view is UITableViewCell || view is UICollectionViewCell { return view }
            if view.accessibilityTraits.contains(.button) { return view }
            if let id = view.accessibilityIdentifier, !id.isEmpty { return view }
            if let label = view.accessibilityLabel, !label.isEmpty { return view }
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                return view
            }

            // No positive signal — stop at any VC root view
            if let vc = view.bt_viewController(), vc.view === view {
                return nil
            }

            current = view.superview
        }

        return nil
    }
    
    /// After the upward walk fails, search inside the nearest SwiftUI hosting view
    /// for any descendant that contains `point` (in window coords) and looks actionable.
    func bt_findSwiftUIActionable(at windowPoint: CGPoint, in window: UIWindow) -> UIView? {
        // Find the nearest hosting view ancestor
        guard let host = bt_nearestHostingView() else { return nil }
        return host.bt_deepSearch(windowPoint: windowPoint, in: window)
    }
    
    private func bt_nearestHostingView() -> UIView? {
        var v: UIView? = self
        while let view = v {
            let name = String(describing: type(of: view))
            if name.contains("Hosting") { return view }
            v = view.superview
        }
        return nil
    }
    
    /// Depth-first search through subviews for the smallest actionable view
    /// whose frame (converted to window) contains the touch point.
    private func bt_deepSearch(windowPoint: CGPoint, in window: UIWindow) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0 else { return nil }

        let localPoint = convert(windowPoint, from: window)
        guard bounds.contains(localPoint) else { return nil }

        // Search children first — deepest/smallest match wins
        for sub in subviews.reversed() {
            if let found = sub.bt_deepSearch(windowPoint: windowPoint, in: window) {
                return found
            }
        }

        let className = String(describing: type(of: self))
        let isContainer = self is UIScrollView
            || self is UIWindow
            || self is UIStackView
            || className.contains("Hosting")
            || className.contains("Container")
            || className.contains("UITransitionView")
            || className.contains("UILayoutContainerView")

        if !isContainer {
            if accessibilityTraits.contains(.button) { return self }
            if let id = accessibilityIdentifier, !id.isEmpty { return self }
            if let label = accessibilityLabel, !label.isEmpty { return self }
            if let gestures = gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) { return self }
            if self is UIControl { return self }
            if self is UITableViewCell || self is UICollectionViewCell { return self }
        }

        return nil
    }
}

// MARK: - UIApplication Swizzle

extension UIApplication {
    var bt_visibleViewController: UIViewController? {
        guard let root = bt_keyWindow?.rootViewController else { return nil }
        return root.bt_topmostUserFacingViewController()
    }
    
    @objc func btt_sendAction(
        _ action: Selector,
        to target: Any?,
        from sender: Any?,
        for event: UIEvent?
    ) -> Bool {
        
        let actionSelector = NSStringFromSelector(action)
        let className = sender.map { String(describing: type(of: $0)) } ?? "nil"
        let targetName = target.map { String(describing: type(of: $0)) } ?? "nil"

        if UIApplication.avoidSender(sender, forTarget: target, action: actionSelector) {
            return btt_sendAction(action, to: target, from: sender, for: event)
        }

        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: className,
                targetId: actionSelector + ":" + targetName,
                action: "tap"
            )
        )

        return btt_sendAction(action, to: target, from: sender, for: event)
    }
    
    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event)

        guard event.type == .touches else { return }
        
        event.allTouches?
            .filter { $0.phase == .ended }
            .forEach { touch in
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { return }
                let point = touch.location(in: window)
                guard let hitView = window.hitTest(point, with: event),
                      hitView != window else { return }

                // 1. bttTrackAction — user defined action
                if let (target, action) = BTViewRegistry.shared.findAction(for: point, in: window) {
                    BTEventEmitter.emitTracked(view: target, point: point, action: action)
                    return
                }
                
                // 2. walk up to find actionable target
                var target = hitView.bt_findActionableTarget()
                
                // 3. SwiftUI fallback — search inside hosting view subtree
                if target == nil {
                    target = hitView.bt_findSwiftUIActionable(at: point, in: window)
                }
                guard let resolvedTarget = target else { return }  // ← truly empty area, skip
                BTEventEmitter.emit(view: resolvedTarget, point: point)
            }
    }
    
    private static func avoidSender(_ sender: Any?, forTarget target: Any?, action: String) -> Bool {
        guard let sender = sender, let target = target else {
            return true
        }
        if let textField = sender as? UITextField {
            // This is required to avoid creating breadcrumbs for every key pressed in a text field.
            let actions = textField.actions(forTarget: target, forControlEvent: .editingChanged)
            return actions?.contains(action) ?? false
        }
        return false
    }

    var bt_keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return windows.first { $0.isKeyWindow }
    }
}

// MARK: - Event Builder
enum BTEventEmitter {

    static func emitTracked(view: UIView, point: CGPoint, action: String) {
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: String(describing: type(of: view)),
                targetId: action,
                action: "tap"
            )
        )
    }

    static func emit(view: UIView, point: CGPoint) {
        let bundleId   = Bundle.main.bundleIdentifier ?? "unknown"
        let actionName = "tap"
        let identifier = extractIdentifier(from: view)
        let targetId   = "\(bundleId):\(actionName):\(identifier)"

        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: String(describing: type(of: view)),
                targetId: targetId,
                action: actionName
            )
        )
    }
    
    static func extractIdentifier(from view: UIView) -> String {

        // 1. accessibility identifier — highest priority (explicitly set by developer)
        if let id = view.accessibilityIdentifier, !id.isEmpty { return id }
        
        // 2. accessibility label
        if let label = view.accessibilityLabel, !label.isEmpty { return label }

        // 3. walk superview chain
        var current = view.superview
        while let v = current {
            if let id = v.accessibilityIdentifier, !id.isEmpty { return id }
            if let label = v.accessibilityLabel, !label.isEmpty { return label }
            current = v.superview
        }

        // 4. UIKit fallbacks
        if let btn = view as? UIButton, let title = btn.currentTitle { return title }
        if let cell = view as? UITableViewCell, let text = cell.textLabel?.text { return text }

        return "unknown"
    }
}

extension UIView {
    func bt_isDescendantOfViewController(_ vc: UIViewController) -> Bool {
        if isDescendant(of: vc.view) { return true }

        for child in vc.children {
            if bt_isDescendantOfViewController(child) { return true }
        }

        return false
    }
    
    func bt_viewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController {
                return vc
            }
            responder = next
        }
        return nil
    }
}

extension UIViewController {
    
    func bt_topmostUserFacingViewController() -> UIViewController {
        if let presented = presentedViewController {
            let className = String(describing: type(of: presented))
            let isSwiftUIInternal = className.contains("PresentationHostingController")
            || className.contains("_TtGC7SwiftUI")
            
            if !isSwiftUIInternal {
                return presented.bt_topmostUserFacingViewController()
            }
        }
        
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.bt_topmostUserFacingViewController() ?? self
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.bt_topmostUserFacingViewController() ?? self
        }
        
        return self
    }
}
*/

//------------------------New ----------------------


import UIKit
import SwiftUI

// MARK: - UIView Associated Object

private var btActionKey: UInt8 = 0

extension UIView {
    var btAction: String? {
        get { objc_getAssociatedObject(self, &btActionKey) as? String }
        set { objc_setAssociatedObject(self, &btActionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - SwiftUI Modifier

public extension View {
    func bttTrackAction(_ action: String) -> some View {
        modifier(BTTrackModifier(action: action))
    }
}

private struct BTTrackModifier: ViewModifier {
    let action: String
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    BTAnchorView(action: action, size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            )
    }
}

// MARK: - UIViewRepresentable

private struct BTAnchorView: UIViewRepresentable {
    let action: String
    let size: CGSize

    func makeUIView(context: Context) -> BTTouchAnchor {
        let view = BTTouchAnchor()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: BTTouchAnchor, context: Context) {
        uiView.action = action
        DispatchQueue.main.async {
            if let superview = uiView.superview {
                uiView.frame = CGRect(origin: .zero, size: superview.bounds.size)
            }
        }
    }
}

// MARK: - Anchor UIView

final class BTTouchAnchor: UIView {
    var action: String = "" {
        didSet { if !action.isEmpty { BTViewRegistry.shared.register(self, action: action) } }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, !action.isEmpty {
            BTViewRegistry.shared.register(self, action: action)
        } else {
            BTViewRegistry.shared.unregister(self)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !action.isEmpty { BTViewRegistry.shared.register(self, action: action) }
    }
}

// MARK: - Global Registry

final class BTViewRegistry {
    static let shared = BTViewRegistry()
    private init() {}

    private struct Entry {
        weak var view: BTTouchAnchor?
        let action: String
    }

    private var entries: [Entry] = []
    private let lock = NSLock()

    func register(_ view: BTTouchAnchor, action: String) {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
        entries.append(Entry(view: view, action: action))
    }

    func unregister(_ view: BTTouchAnchor) {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
    }

    func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.lock(); defer { lock.unlock() }
        entries.removeAll { $0.view == nil }

        let topVC = UIApplication.shared.bt_visibleViewController

        var best: (UIView, String, CGFloat)?
        for entry in entries {
            guard let anchor = entry.view, anchor.window == window else { continue }

            // ── VC ownership check ──────────────────────────────────────────
            if let topVC = topVC {
                guard anchor.bt_isOwnedByVC(topVC) else { continue }
            }

            // ── Use frame-in-window for point check — works for SwiftUI ────
            let anchorFrameInWindow = anchor.convert(anchor.bounds, to: window)
            guard anchorFrameInWindow.contains(point) else { continue }

            let area = anchorFrameInWindow.width * anchorFrameInWindow.height
            if best == nil || area < best!.2 {
                best = (anchor, entry.action, area)
            }
        }
        return best.map { ($0.0, $0.1) }
    }
}

// MARK: - UIView Helpers

extension UIView {

    func bt_isInSwiftUIHosting() -> Bool {
        var current: UIView? = self
        while let view = current {
            let className = String(describing: type(of: view))
            if className.contains("Hosting") { return true }
            current = view.superview
        }
        return false
    }

    /// Checks ownership via responder chain — works for UIKit and SwiftUI
    func bt_isOwnedByVC(_ topVC: UIViewController) -> Bool {
        var responder: UIResponder? = self
        while let next = responder {
            if let vc = next as? UIViewController {
                // Direct match
                if vc === topVC { return true }
                // VC is child of topVC
                if topVC.bt_containsVC(vc) { return true }
                // VC is in same navigation stack as topVC
                if let nav = topVC.navigationController,
                   nav.viewControllers.contains(where: { $0 === vc }) { return true }
                if let nav = vc.navigationController,
                   nav.viewControllers.contains(where: { $0 === topVC }) { return true }
                return false
            }
            responder = next.next
        }
        return true
    }

    func bt_isDescendantOfViewController(_ vc: UIViewController) -> Bool {
        if isDescendant(of: vc.view) { return true }
        for child in vc.children {
            if bt_isDescendantOfViewController(child) { return true }
        }
        if let presented = vc.presentedViewController {
            if bt_isDescendantOfViewController(presented) { return true }
        }
        return false
    }

    func bt_findActionableTarget() -> UIView? {
        var current: UIView? = self

        while let view = current {
            if view is UIWindow { return nil }

            let className = String(describing: type(of: view))

            guard view.isUserInteractionEnabled,
                  !view.isHidden,
                  view.alpha > 0 else {
                current = view.superview
                continue
            }

            let isContainer = view is UIStackView
                || view is UIScrollView
                || className.contains("Hosting")
                || className.contains("Container")
                || className.contains("UITransitionView")
                || className.contains("UILayoutContainerView")

            if isContainer {
                current = view.superview
                continue
            }

            if view is UIControl { return view }
            if view is UITableViewCell || view is UICollectionViewCell { return view }
            if view.accessibilityTraits.contains(.button) { return view }
            if let id = view.accessibilityIdentifier, !id.isEmpty { return view }
            if let label = view.accessibilityLabel, !label.isEmpty { return view }
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                return view
            }

            if let vc = view.bt_viewController(), vc.view === view {
                return nil
            }

            current = view.superview
        }
        return nil
    }

    func bt_findSwiftUIActionable(at windowPoint: CGPoint, in window: UIWindow) -> UIView? {
        guard let hostingRoot = bt_rootHostingView() else { return nil }
        return hostingRoot.bt_deepSearch(windowPoint: windowPoint, in: window)
    }

    private func bt_rootHostingView() -> UIView? {
        var result: UIView? = nil
        var current: UIView? = self
        while let view = current {
            let name = String(describing: type(of: view))
            if name.contains("Hosting") { result = view }
            current = view.superview
        }
        return result
    }

    private func bt_deepSearch(windowPoint: CGPoint, in window: UIWindow) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0 else { return nil }

        let localPoint = convert(windowPoint, from: window)
        guard bounds.contains(localPoint) else { return nil }

        for sub in subviews.reversed() {
            if let found = sub.bt_deepSearch(windowPoint: windowPoint, in: window) {
                return found
            }
        }

        let className = String(describing: type(of: self))
        let isContainer = self is UIScrollView
            || self is UIWindow
            || self is UIStackView
            || className.contains("Hosting")
            || className.contains("Container")
            || className.contains("UITransitionView")
            || className.contains("UILayoutContainerView")

        if !isContainer {
            if accessibilityTraits.contains(.button) { return self }
            if let id = accessibilityIdentifier, !id.isEmpty { return self }
            if let label = accessibilityLabel, !label.isEmpty { return self }
            if let gestures = gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) { return self }
            if self is UIControl { return self }
            if self is UITableViewCell || self is UICollectionViewCell { return self }
        }
        return nil
    }

    func bt_viewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let vc = next as? UIViewController { return vc }
            responder = next
        }
        return nil
    }
}

// MARK: - UIViewController Helpers

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

// MARK: - UIApplication Swizzle

extension UIApplication {

    var bt_visibleViewController: UIViewController? {
        guard let root = bt_keyWindow?.rootViewController else { return nil }
        return root.bt_topmostUserFacingViewController()
    }

    @objc func btt_sendAction(
        _ action: Selector,
        to target: Any?,
        from sender: Any?,
        for event: UIEvent?
    ) -> Bool {
        let actionSelector = NSStringFromSelector(action)
        let className = sender.map { String(describing: type(of: $0)) } ?? "nil"
        let targetName = target.map { String(describing: type(of: $0)) } ?? "nil"

        if UIApplication.avoidSender(sender, forTarget: target, action: actionSelector) {
            return btt_sendAction(action, to: target, from: sender, for: event)
        }

        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: className,
                targetId: actionSelector + ":" + targetName,
                action: "tap"
            )
        )
        return btt_sendAction(action, to: target, from: sender, for: event)
    }

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event)

        guard event.type == .touches else { return }

        event.allTouches?
            .filter { $0.phase == .began }
            .forEach { touch in
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { return }
                let point = touch.location(in: window)
                guard let hitView = window.hitTest(point, with: event),
                      hitView != window else { return }

                // 1. bttTrackAction — validated against current VC inside findAction
                if let (target, action) = BTViewRegistry.shared.findAction(for: point, in: window) {
                    BTEventEmitter.emitTracked(view: target, point: point, action: action)
                    return
                }

                // 2. VC hierarchy check for auto tracking
                if let topVC = UIApplication.shared.bt_visibleViewController {
                    guard hitView.bt_isDescendantOfViewController(topVC) else { return }
                }

                // 3. SwiftUI path
                if hitView.bt_isInSwiftUIHosting() {
                    if let target = hitView.bt_findSwiftUIActionable(at: point, in: window) {
                        BTEventEmitter.emit(view: target, point: point)
                    }
                    return
                }

                // 4. UIKit path
                guard let target = hitView.bt_findActionableTarget() else { return }
                BTEventEmitter.emit(view: target, point: point)
            }
    }

    private static func avoidSender(_ sender: Any?, forTarget target: Any?, action: String) -> Bool {
        guard let sender = sender, let target = target else { return true }
        if let textField = sender as? UITextField {
            let actions = textField.actions(forTarget: target, forControlEvent: .editingChanged)
            return actions?.contains(action) ?? false
        }
        return false
    }

    var bt_keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return windows.first { $0.isKeyWindow }
    }
}

// MARK: - Event Builder

enum BTEventEmitter {

    static func emitTracked(view: UIView, point: CGPoint, action: String) {
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: String(describing: type(of: view)),
                targetId: action,
                action: "tap"
            )
        )
    }

    static func emit(view: UIView, point: CGPoint) {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let actionName = "tap"
        let identifier = extractIdentifier(from: view)
        let targetId = "\(bundleId):\(actionName):\(identifier)"

        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: String(describing: type(of: view)),
                targetId: targetId,
                action: actionName
            )
        )
    }

    static func extractIdentifier(from view: UIView) -> String {
        if let id = view.accessibilityIdentifier, !id.isEmpty { return id }
        if let label = view.accessibilityLabel, !label.isEmpty { return label }

        var current = view.superview
        while let v = current {
            if let id = v.accessibilityIdentifier, !id.isEmpty { return id }
            if let label = v.accessibilityLabel, !label.isEmpty { return label }
            current = v.superview
        }

        if let btn = view as? UIButton, let title = btn.currentTitle { return title }
        if let cell = view as? UITableViewCell, let text = cell.textLabel?.text { return text }

        return "unknown"
    }
}
