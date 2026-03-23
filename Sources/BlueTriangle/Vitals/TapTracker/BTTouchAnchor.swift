//
//  BTTouchAnchor.swift
//  blue-triangle
//
//  Created by Ashok Singh on 19/03/26.
//
#if os(iOS)
#if canImport(SwiftUI)
import SwiftUI
#endif

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
#endif
