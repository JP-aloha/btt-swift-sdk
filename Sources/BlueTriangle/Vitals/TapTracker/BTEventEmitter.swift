//
//  BTEventEmitter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 19/03/26.
//

import SwiftUI

enum BTEventEmitter {

    static func emitTracked(view: UIView, point: CGPoint, action: String) {
        let (x, y) = normalize(point: point)
        BlueTriangle.collectBreadcrumb(
                UserEvent(
                    targetClass: String(describing: type(of: view)),
                    targetId: action,
                    action: "tap",
                    x: x,
                    y: y
                )
            )
    }

    static func emit(view: UIView, point: CGPoint) {
        let (x, y) = normalize(point: point)
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        let actionName = "tap"
        let identifier = extractIdentifier(from: view)
        let targetId = "\(bundleId):\(actionName):\(identifier)"
        
        BlueTriangle.collectBreadcrumb(
               UserEvent(
                   targetClass: String(describing: type(of: view)),
                   targetId: targetId,
                   action: actionName,
                   x: x,
                   y: y
               )
           )
    }
    
    static func normalize(point: CGPoint) -> (Float, Float) {
        let x = Float(point.x)
        let y = Float(point.y)
        return (x, y)
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
