//
//  UserEventFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 02/03/26.
//

#if os(iOS)
#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - UIApplication Swizzle
extension UIApplication {
    @objc func swizzled_sendAction(
        _ action: Selector,
        to target: Any?,
        from sender: Any?,
        for event: UIEvent?
    ) -> Bool {
        let actionSelector = NSStringFromSelector(action)
        let className = sender.map { String(describing: type(of: $0)) } ?? "nil"
        let targetName = target.map { String(describing: type(of: $0)) } ?? "nil"

        if UIApplication.avoidSender(sender, forTarget: target, action: actionSelector) {
            return swizzled_sendAction(action, to: target, from: sender, for: event)
        }
        
        var x: Float = 0
        var y: Float = 0
        var timestamp: TimeInterval = Date().timeIntervalSince1970
        
        if let touch = event?.allTouches?.first,
           let window = touch.window ?? UIApplication.shared.bt_keyWindow {
            let point = touch.location(in: window)
            x = Float(point.x)
            y = Float(point.y)
            timestamp = touch.timestamp
        }
        
        if shouldTrackEvent(timestamp: timestamp, x: x, y: y) {
            BlueTriangle.collectBreadcrumb(
                UserEvent(
                    targetClass: className,
                    targetId: actionSelector + ":" + targetName,
                    action: Constants.tapAction,
                    x: x,
                    y: y
                )
            )
        }
        return swizzled_sendAction(action, to: target, from: sender, for: event)
    }

    @objc func swizzled_sendEvent(_ event: UIEvent) {
        swizzled_sendEvent(event)

        guard event.type == .touches else { return }

        event.allTouches?
            .filter { $0.phase == .began || $0.phase == .ended}
            .forEach { touch in
                BlueTriangle.groupTimer.setLastAction(Date())
                guard let window = touch.window ?? UIApplication.shared.bt_keyWindow else { return }
                let point = touch.location(in: window)
                let x = Float(point.x)
                let y = Float(point.y)
                let timestamp = touch.timestamp
                
                // Skip if duplicate by coordinate and timestamp
                guard shouldTrackEvent(timestamp: timestamp, x: x, y: y) else { return }
                
                guard let hitView = window.hitTest(point, with: event),
                      hitView != window else { return }

                if touch.phase == .ended {
                    if let tabBar = hitView.bt_findTabBar() {
                        BTEventEmitter.emit(view: tabBar, point: point)
                        return
                    }
                }
                
                // All other tracking — use .began
                guard touch.phase == .began else { return }
                
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
}

extension UIApplication {
    private static var lastTrackedEvent: (timestamp: TimeInterval, x: Float, y: Float)?
    private static let dedupThreshold: TimeInterval = 0.2 // 200ms threshold
    private static let coordinateThreshold: Float = 0.02 // 2% of screen
    
    func shouldTrackEvent(timestamp: TimeInterval, x: Float, y: Float) -> Bool {
        // If no previous event, track it
        guard let last = UIApplication.lastTrackedEvent else {
            UIApplication.lastTrackedEvent = (timestamp, x, y)
            return true
        }
        
        // Check if within time threshold AND same coordinate
        let timeDiff = timestamp - last.timestamp
        let xDiff = abs(last.x - x)
        let yDiff = abs(last.y - y)
        
        let isDuplicate = timeDiff < UIApplication.dedupThreshold &&
                          xDiff < UIApplication.coordinateThreshold &&
                          yDiff < UIApplication.coordinateThreshold
        
        if !isDuplicate {
            UIApplication.lastTrackedEvent = (timestamp, x, y)
        }
        
        return !isDuplicate
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
    
    var bt_visibleViewController: UIViewController? {
        guard let root = bt_keyWindow?.rootViewController else { return nil }
        return root.bt_topmostUserFacingViewController()
    }
}

extension UIApplication {
    
    var activeKeyWindow: UIWindow? {
        return self.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    func topViewController(base: UIViewController? = UIApplication.shared.activeKeyWindow?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}

#endif
