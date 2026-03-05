import UIKit
import SwiftUI

// MARK: - UIView Associated Object (stores btTrack action)

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
        background(BTRegisterView(action: action))
    }
}

private struct BTRegisterView: UIViewRepresentable {
    let action: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.btAction = action
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.btAction = action
    }
}

// MARK: - UIApplication Swizzle

extension UIApplication {

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if let touches = event.allTouches {
            for touch in touches where touch.phase == .ended {
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { continue }
                let point = touch.location(in: window)
                guard let hitView = window.hitTest(point, with: event) else { continue }

                // 1. Check btTrack action first (walk hierarchy for .btTrack modifier)
                if let (target, action) = hitView.bt_findTrackedView() {
                    BTEventEmitter.emitTracked(view: target, point: point, action: action)
                    continue
                }

                // 2. Fall back to existing meaningful target logic
                guard let target = hitView.bt_meaningfulTarget() else { continue }
                BTEventEmitter.emit(view: target, point: point)
            }
        }
        swizzled_sendEvent(event)
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

// MARK: - UIView Hierarchy Helpers
private extension UIView {

    /// Walk UP hierarchy, at each level search ENTIRE subtree for btAction
    func bt_findTrackedView() -> (UIView, String)? {
        var current: UIView? = self
        while let view = current {
            if let action = view.bt_findActionInSubtree() {
                return (view, action)
            }
            current = view.superview
        }
        return nil
    }

    /// Recursively search all subviews for btAction
    func bt_findActionInSubtree() -> String? {
        if let action = btAction { return action }
        for subview in subviews {
            if let action = subview.bt_findActionInSubtree() {
                return action
            }
        }
        return nil
    }

    /// Walk up to find meaningful UIKit target
    func bt_meaningfulTarget() -> UIView? {
        var current: UIView? = self
        while let view = current {
            if view is UIControl { return view }
            if view is UITableViewCell || view is UICollectionViewCell { return view }
            if view is UITabBar { return view }
            if view is UINavigationBar { return view }
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                return view
            }
            if view.isAccessibilityElement { return view }
            current = view.superview
        }
        return nil
    }
}

// MARK: - Event Builder

enum BTEventEmitter {

    /// Called when .btTrack modifier is used — uses the exact action name provided
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

    /// Called for all other views — auto-detects type
    static func emit(view: UIView, point: CGPoint) {
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        var actionName = "tap"
        var extra: [String: Any] = [
            "x": Double(point.x),
            "y": Double(point.y)
        ]

        let identifier = extractIdentifier(from: view)
        let label = extractLabel(from: view)

        switch view {
        case let b as UIButton:
            actionName = "buttonTap"
            extra["title"] = b.currentTitle ?? label ?? ""

        case let s as UISwitch:
            actionName = "switchToggle"
            extra["value"] = s.isOn

        case let s as UISlider:
            actionName = "sliderChange"
            extra["value"] = Double(s.value)

        case let s as UISegmentedControl:
            actionName = "segmentChange"
            extra["selectedIndex"] = s.selectedSegmentIndex
            extra["selectedTitle"] = s.titleForSegment(at: s.selectedSegmentIndex) ?? ""

        case let s as UIStepper:
            actionName = "stepperChange"
            extra["value"] = s.value

        case let cell as UITableViewCell:
            actionName = "tableCellTap"
            extra["text"] = cell.textLabel?.text ?? ""

        case let cell as UICollectionViewCell:
            actionName = "collectionCellTap"
            extra["reuseId"] = cell.reuseIdentifier ?? ""

        case is UITabBar:
            actionName = "tabBarTap"

        case is UINavigationBar:
            actionName = "navigationBarTap"

        default:
            actionName = "tap"
        }

        if isSwiftUIView(view) {
            extra["framework"] = "SwiftUI"
        }

        let targetClass = String(describing: type(of: view))
        let targetId = "\(bundleId):\(actionName):\(identifier)"
        BlueTriangle.collectBreadcrumb(
            UserEvent(
                targetClass: targetClass,
                targetId: targetId,
                action: "tap"
            )
        )
    }

    // MARK: - Helpers
    private static func extractIdentifier(from view: UIView) -> String {
        if view.isAccessibilityElement,
           let id = view.accessibilityIdentifier, !id.isEmpty {
            return id
        }
        if let elements = view.accessibilityElements {
            for element in elements {
                if let identifiable = element as? UIAccessibilityIdentification,
                   let id = identifiable.accessibilityIdentifier, !id.isEmpty {
                    return id
                }
            }
        }
        var current = view.superview
        while let v = current {
            if v.isAccessibilityElement,
               let id = v.accessibilityIdentifier, !id.isEmpty {
                return id
            }
            if let elements = v.accessibilityElements {
                for element in elements {
                    if let identifiable = element as? UIAccessibilityIdentification,
                       let id = identifiable.accessibilityIdentifier, !id.isEmpty {
                        return id
                    }
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
}
