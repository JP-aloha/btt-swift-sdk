
import UIKit
import ObjectiveC.runtime

// MARK: - UIApplication + sendEvent

extension UIApplication {
    
    @objc func swizzled_sendEvent(_ event: UIEvent) {
        if let touches = event.allTouches {
            for touch in touches where touch.phase == .ended {
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { continue }
                let point = touch.location(in: window)
                guard let hitView = window.hitTest(point, with: event) else { continue }
                guard let target = hitView.bt_meaningfulTarget() else { continue }
                BTEventEmitter.emit(view: target, point: point)
            }
        }
        swizzled_sendEvent(event)
    }
    
    /// Safe keyWindow accessor for iOS 13+
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

// MARK: - UIView: walk up to meaningful target

private extension UIView {

    /// Starting from `self`, walks up the superview chain and returns the
    /// first view that is a recognisable interaction target:
    ///   UIControl → UITableViewCell → UICollectionViewCell
    ///   → view with gesture recognisers → SwiftUI hosting view
    func bt_meaningfulTarget() -> UIView? {
        var current: UIView? = self

        while let view = current {

            //  UIKit Controls (UIButton, UISwitch, etc.)
            if view is UIControl {
                return view
            }

            // Table / Collection Cells
            if view is UITableViewCell || view is UICollectionViewCell {
                return view
            }

            // Tab Bar
            if view is UITabBar {
                return view
            }

            // Navigation Bar
            if view is UINavigationBar {
                return view
            }

            // Tap Gesture (custom tappable UIView)
            if let gestures = view.gestureRecognizers,
               gestures.contains(where: { $0 is UITapGestureRecognizer }) {
                return view
            }

            // SwiftUI Hosting Views
           /* let className = String(describing: type(of: view))
            if className.contains("UIHosting")
                || className.contains("HostingView")
                || className.contains("SwiftUI") {
                return view
            }*/

            current = view.superview
        }

        return nil
    }
}

// MARK: - Event Builder

private enum BTEventEmitter {

    static func emit(view: UIView, point: CGPoint) {

        let bundleId  = Bundle.main.bundleIdentifier ?? "unknown"
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        var actionName = "tap"
        var extra: [String: Any] = [
            "x": Double(point.x),
            "y": Double(point.y)
        ]

        // MARK: - Extract Identifier Safely

        let identifier = extractIdentifier(from: view)
        let label = extractLabel(from: view)

        // MARK: - Detect Control Type

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

        // MARK: - Detect SwiftUI

        if isSwiftUIView(view) {
            extra["framework"] = "SwiftUI"
        }

        let targetId = "\(bundleId):\(identifier ?? label ?? "unknown")"

        var payload: [String: Any] = [
            "type":        "user.event",
            "timestamp":   timestamp,
            "action":      actionName,
            "targetClass": String(describing: type(of: view)),
            "targetId":    targetId
        ]

        extra.forEach { payload[$0.key] = $0.value }

        guard
            let data = try? JSONSerialization.data(withJSONObject: payload, options: .sortedKeys),
            let json = String(data: data, encoding: .utf8)
        else { return }

        print("[BT] \(json)")
    }

    // MARK: - Helpers

    private static func extractIdentifier(from view: UIView) -> String? {
        if let id = view.accessibilityIdentifier, !id.isEmpty {
            return id
        }

        // Walk up hierarchy for SwiftUI hosting cases
        var current: UIView? = view.superview
        while let v = current {
            if let id = v.accessibilityIdentifier, !id.isEmpty {
                return id
            }
            current = v.superview
        }

        return nil
    }

    private static func extractLabel(from view: UIView) -> String? {
        if let label = view.accessibilityLabel, !label.isEmpty {
            return label
        }

        if let button = view as? UIButton {
            return button.currentTitle
        }

        return nil
    }

    private static func isSwiftUIView(_ view: UIView) -> Bool {
        let name = String(describing: type(of: view))
        return name.contains("SwiftUI")
            || name.contains("UIHosting")
            || name.contains("HostingView")
    }
}
/*
private enum BTEventEmitter {

    static func emit(view: UIView, point: CGPoint) {

        let bundleId  = Bundle.main.bundleIdentifier ?? "unknown"
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        var actionName = "tap"
        var extra: [String: Any] = [
            "x": Double(point.x),
            "y": Double(point.y)
        ]

        switch view {
        case let b as UIButton:
            actionName = "buttonTap"
            var title: String = b.currentTitle
                ?? b.titleLabel?.text
                ?? b.title(for: .normal)
                ?? ""
            if #available(iOS 15.0, *) {
                if let cfgTitle = b.configuration?.title, !cfgTitle.isEmpty {
                    title = cfgTitle
                }
            }
            extra["title"] = title

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

        case is UITableViewCell, is UICollectionViewCell:
            actionName = "cellTap"

        default:
            let cls = String(describing: type(of: view))
            if cls.contains("HostingView") || cls.contains("SwiftUI") {
                extra["framework"] = "SwiftUI"
            }
        }

        let targetId = "\(bundleId):\(view.accessibilityIdentifier ?? view.accessibilityLabel ?? "unknown")"

        var payload: [String: Any] = [
            "type":        "user.event",
            "timestamp":   timestamp,
            "action":      actionName,
            "targetClass": String(describing: type(of: view)),
            "targetId":    targetId
        ]
        extra.forEach { payload[$0.key] = $0.value }

        guard
            let data = try? JSONSerialization.data(withJSONObject: payload, options: .sortedKeys),
            let json = String(data: data, encoding: .utf8)
        else { return }

        print("[BT] \(json)")
    }
}*/
