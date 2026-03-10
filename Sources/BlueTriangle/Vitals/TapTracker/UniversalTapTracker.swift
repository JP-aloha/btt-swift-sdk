import UIKit
import SwiftUI

// MARK: - UIView Associated Object

private var btActionKey: UInt8 = 0

/*extension UIView {
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
            .overlay(
                GeometryReader { geo in
                    BTAnchorView(action: action, size: geo.size)
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
        // force frame to match parent exactly
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
        didSet {
            if !action.isEmpty {
                BTViewRegistry.shared.register(self, action: action)
            }
        }
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
        // re-register on layout so frame is always up to date
        if !action.isEmpty {
            BTViewRegistry.shared.register(self, action: action)
        }
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
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
        entries.append(Entry(view: view, action: action))
    }

    func unregister(_ view: BTTouchAnchor) {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
    }

    /// Use CALayer hit test — bypasses SwiftUI gesture system entirely
    func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.lock()
        defer { lock.unlock() }

        entries.removeAll { $0.view == nil }

        // pick smallest matching frame = most specific view
        var best: (UIView, String, CGFloat)?

        for entry in entries {
            guard let anchor = entry.view, anchor.window == window else { continue }

            // use CALayer hitTest for reliability
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

// MARK: - UIApplication Swizzle

extension UIApplication {

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event) 
        guard event.type == .touches else { return }

        event.allTouches?
            .filter { $0.phase == .ended }
            .forEach { touch in
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { return }
                let point = touch.location(in: window)

                // 1. Check registry using CALayer-based frame matching
                if let (target, action) = BTViewRegistry.shared.findAction(for: point, in: window) {
                    BTEventEmitter.emitTracked(view: target, point: point, action: action)
                    return
                }

                // 2. Fall back to meaningful target
                guard let hitView = window.hitTest(point, with: event) else { return }
                guard let target = hitView.bt_meaningfulTarget() else { return }
                BTEventEmitter.emit(view: target, point: point)
            }
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

// MARK: - UIView Helpers

private extension UIView {

    
    func bt_meaningfulTarget() -> UIView? {
        var current: UIView? = self
        while let view = current {
            // skip non-interactive
            guard view.isUserInteractionEnabled,
                  !view.isHidden,
                  view.alpha > 0 else {
                current = view.superview
                continue
            }

            // skip containers that are never actionable
            if view is UIWindow ||
               isSwiftUIHostingView(view) {
                current = view.superview
                continue
            }

            // only real interactive targets
            if view is UIControl { return view }
            if view is UITableViewCell || view is UICollectionViewCell { return view }
            if view is UITabBar { return view }
            if view is UINavigationBar { return view }
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                return view
            }
            
            //  SwiftUI button detection
            if isSwiftUIButtonView(view) { return view }
            
            // SwiftUI accessibility-based tap detection
            if view.accessibilityActivate() != false,
               view.accessibilityTraits.contains(.button) {
                return view
            }

            current = view.superview
        }
        return nil
    }
    
    func isSwiftUIHostingView(_ view: UIView) -> Bool {
        let name = String(describing: type(of: view))
        return name.contains("UIHosting") || name.contains("HostingView") || name.contains("UILayoutContainerView")
    }
    
    
    func isSwiftUIButtonView(_ view: UIView) -> Bool {
        let name = String(describing: type(of: view))
        
        // SwiftUI buttons resolve to these internal view types
        if name.contains("ButtonHostingView") ||
           name.contains("SwiftUI.UIKitButton") ||
           name.contains("_TtC7SwiftUI") {
            return true
        }

        if let gestures = view.gestureRecognizers,
           gestures.contains(where: {
               let gestureName = String(describing: type(of: $0))
               return gestureName.contains("SwiftUI") ||
                      gestureName.contains("TapGesture") ||
                      gestureName.contains("UISystemGestureGate")
           }) {
            return true
        }

        if view.accessibilityTraits.contains(.button),
           view.isAccessibilityElement {
            return true
        }

        return false
    }
}

// MARK: - Event Builder

enum BTEventEmitter {

    static func emitTracked(view: UIView, point: CGPoint, action: String) {
        let targetClass = String(describing: type(of: view))
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: targetClass,
                targetId: action,
                action: "tap"
            )
        )
    }

    static func emit(view: UIView, point: CGPoint) {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let targetClass = String(describing: type(of: view))
        let identifier = extractIdentifier(from: view)
        let label = extractLabel(from: view)
        let actionName = extractActionName(from: view)
        var extra: [String: Any] = [
            "x": Double(point.x),
            "y": Double(point.y)
        ]
        
        if isSwiftUIView(view) {
            extra["framework"] = "SwiftUI"
        }

        let targetId = "\(bundleId):\(actionName):\(identifier)"
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: targetClass,
                targetId: targetId,
                action: "tap"
            )
        )
    }
    
    private static func extractActionName(from view: UIView) -> String {
        // UIKit controls — use class name directly
        if view is UIButton           { return String(describing: type(of: view)) }
        if view is UISwitch           { return String(describing: type(of: view)) }
        if view is UISlider           { return String(describing: type(of: view)) }
        if view is UISegmentedControl { return String(describing: type(of: view)) }
        if view is UIStepper          { return String(describing: type(of: view)) }
        if view is UITableViewCell    { return String(describing: type(of: view)) }
        if view is UICollectionViewCell { return String(describing: type(of: view)) }
        if view is UITabBar           { return String(describing: type(of: view)) }
        if view is UINavigationBar    { return String(describing: type(of: view)) }

        // SwiftUI — use actual class name
        return String(describing: type(of: view))
    }

    private static func extractIdentifier(from view: UIView) -> String {
        if view.isAccessibilityElement,
           let id = view.accessibilityIdentifier, !id.isEmpty { return id }
        if let elements = view.accessibilityElements {
            for element in elements {
                if let identifiable = element as? UIAccessibilityIdentification,
                   let id = identifiable.accessibilityIdentifier, !id.isEmpty { return id }
            }
        }
        var current = view.superview
        while let v = current {
            if v.isAccessibilityElement,
               let id = v.accessibilityIdentifier, !id.isEmpty { return id }
            if let elements = v.accessibilityElements {
                for element in elements {
                    if let identifiable = element as? UIAccessibilityIdentification,
                       let id = identifiable.accessibilityIdentifier, !id.isEmpty { return id }
                }
            }
            current = v.superview
        }
        return "unknown"
    }

    private static func extractLabel(from view: UIView) -> String? {
        if let label = view.accessibilityLabel, !label.isEmpty { return label }
        if let button = view as? UIButton { return button.currentTitle }
        return nil
    }

    private static func isSwiftUIView(_ view: UIView) -> Bool {
        let name = String(describing: type(of: view))
        return name.contains("SwiftUI") || name.contains("UIHosting") || name.contains("HostingView")
    }
}*/


//--------------New

import UIKit
import SwiftUI

// MARK: - SwiftUI Element Type Detection

enum BTSwiftUIElementType: String {
    case button         = "buttonTap"
    case toggle         = "switchToggle"
    case slider         = "sliderChange"
    case stepper        = "stepperChange"
    case segmented      = "segmentChange"
    case datePicker     = "datePickerChange"
    case textField      = "textFieldTap"
    case navigationLink = "navigationLinkTap"
    case menu           = "menuTap"
    case picker         = "pickerTap"
    case unknown        = "tap"

    /// Detect SwiftUI element type from UIView class name
    static func detect(from view: UIView) -> BTSwiftUIElementType? {
        // walk up to find a recognizable SwiftUI host
        var current: UIView? = view
        while let v = current {
            let name = String(describing: type(of: v))
            if let type_ = BTSwiftUIElementType.from(className: name) {
                return type_
            }
            current = v.superview
        }
        return nil
    }

    static func from(className: String) -> BTSwiftUIElementType? {
        // Button variants
        if className.contains("ButtonHost") ||
           className.contains("UIKitButton") ||
           className.contains("ButtonStyleBody") ||
           className.contains("PrimitiveButtonStyleBody") ||
           className.contains("_ButtonGestureView") {
            return .button
        }

        // Toggle / Switch
        if className.contains("UIKitSwitch") ||
           className.contains("ToggleStyleBody") ||
           className.contains("SwitchToggle") {
            return .toggle
        }

        // Slider
        if className.contains("UIKitSlider") ||
           className.contains("SliderHost") {
            return .slider
        }

        // Stepper
        if className.contains("UIKitStepper") ||
           className.contains("StepperHost") {
            return .stepper
        }

        // Segmented Control / Picker
        if className.contains("UIKitSegmentedControl") ||
           className.contains("SegmentedControl") {
            return .segmented
        }

        // Date Picker
        if className.contains("UIKitDatePicker") ||
           className.contains("DatePickerHost") {
            return .datePicker
        }

        // TextField
        if className.contains("UIKitTextField") ||
           className.contains("TextFieldHost") {
            return .textField
        }

        // NavigationLink
        if className.contains("NavigationLink") ||
           className.contains("UIKitNavigationButton") {
            return .navigationLink
        }

        // Menu
        if className.contains("MenuHost") ||
           className.contains("UIKitMenuButton") {
            return .menu
        }

        // Picker
        if className.contains("UIKitPickerView") ||
           className.contains("PickerHost") {
            return .picker
        }

        return nil
    }
}

// MARK: - UIView Actionability Check

extension UIView {

    /// Returns true if this view is a real interactive target
    func bt_isActionable() -> Bool {
        guard isUserInteractionEnabled, !isHidden, alpha > 0 else { return false }

        // UIKit controls
        if self is UIControl { return true }
        if self is UITableViewCell || self is UICollectionViewCell { return true }
        if self is UITabBar || self is UINavigationBar { return true }

        // has tap gesture on self
        if let gestures = gestureRecognizers,
           gestures.contains(where: { $0 is UITapGestureRecognizer }) {
            return true
        }

        // has tap gesture on direct superview (SwiftUI wraps buttons this way)
        if let gestures = superview?.gestureRecognizers,
           gestures.contains(where: { $0 is UITapGestureRecognizer }) {
            return true
        }

        // SwiftUI element detection
        if BTSwiftUIElementType.detect(from: self) != nil {
            return true
        }

        return false
    }

    /// Resolve the action name for this view
    func bt_resolveActionName() -> String {
        // UIKit
        if self is UIButton { return "buttonTap" }
        if self is UISwitch { return "switchToggle" }
        if self is UISlider { return "sliderChange" }
        if self is UIStepper { return "stepperChange" }
        if self is UISegmentedControl { return "segmentChange" }
        if self is UIDatePicker { return "datePickerChange" }
        if self is UITextField { return "textFieldTap" }
        if self is UITableViewCell { return "tableCellTap" }
        if self is UICollectionViewCell { return "collectionCellTap" }
        if self is UITabBar { return "tabBarTap" }
        if self is UINavigationBar { return "navigationBarTap" }

        // SwiftUI
        return BTSwiftUIElementType.detect(from: self)?.rawValue ?? "tap"
    }
}

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
        didSet {
            if !action.isEmpty {
                BTViewRegistry.shared.register(self, action: action)
            }
        }
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
        if !action.isEmpty {
            BTViewRegistry.shared.register(self, action: action)
        }
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
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
        entries.append(Entry(view: view, action: action))
    }

    func unregister(_ view: BTTouchAnchor) {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll { $0.view == nil || $0.view === view }
    }

    func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.lock()
        defer { lock.unlock() }

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
    }
}

// MARK: - UIApplication Swizzle

extension UIApplication {

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event)

        guard event.type == .touches else { return }

        event.allTouches?
            .filter { $0.phase == .ended }
            .forEach { touch in
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { return }
                let point = touch.location(in: window)
                guard let hitView = window.hitTest(point, with: event) else { return }

                // 1. bttTrackAction — exact user defined action name
                if let (target, action) = BTViewRegistry.shared.findAction(for: point, in: window) {
                    BTEventEmitter.emitTracked(view: target, point: point, action: action)
                    return
                }

                // 2. only track real actionable views
                guard hitView.bt_isActionable() else { return }
                BTEventEmitter.emit(view: hitView, point: point)
            }
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
        let targetClass = String(describing: type(of: view))
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: targetClass,
                targetId: action,
                action: "tap"
            )
        )
    }

    static func emit(view: UIView, point: CGPoint) {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let actionName = view.bt_resolveActionName()
        let identifier = extractIdentifier(from: view)
        let targetClass = String(describing: type(of: view))
        let targetId = "\(bundleId):\(actionName):\(identifier)"

        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: targetClass,
                targetId: targetId,
                action: actionName
            )
        )
    }

    static func extractIdentifier(from view: UIView) -> String {
        if view.isAccessibilityElement,
           let id = view.accessibilityIdentifier, !id.isEmpty { return id }
        if let elements = view.accessibilityElements {
            for element in elements {
                if let identifiable = element as? UIAccessibilityIdentification,
                   let id = identifiable.accessibilityIdentifier, !id.isEmpty { return id }
            }
        }
        var current = view.superview
        while let v = current {
            if v.isAccessibilityElement,
               let id = v.accessibilityIdentifier, !id.isEmpty { return id }
            if let elements = v.accessibilityElements {
                for element in elements {
                    if let identifiable = element as? UIAccessibilityIdentification,
                       let id = identifiable.accessibilityIdentifier, !id.isEmpty { return id }
                }
            }
            current = v.superview
        }
        return "unknown"
    }
}
