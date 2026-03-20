//
//  BTViewRegistry.swift
//  blue-triangle
//
//  Created by Ashok Singh on 19/03/26.
//

import SwiftUI

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
        lock.sync {
            entries.removeAll { $0.view == nil || $0.view === view }
            entries.append(Entry(view: view, action: action))
        }
    }

    func unregister(_ view: BTTouchAnchor) {
        lock.sync {
            entries.removeAll { $0.view == nil || $0.view === view }
        }
    }

    func findAction(for point: CGPoint, in window: UIWindow) -> (UIView, String)? {
        lock.sync {
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
}
