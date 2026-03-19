//
//  BTTrackModifier.swift
//  blue-triangle
//
//  Created by Ashok Singh on 19/03/26.
//

import SwiftUI

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

// MARK: - SwiftUI Modifier
public extension View {
    func bttTrackAction(_ action: String) -> some View {
        modifier(BTTrackModifier(action: action))
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
    
    func bt_findTabBar() -> UITabBar? {
        if let tabBar = self as? UITabBar { return tabBar }
        
        var current = superview
        while let view = current {
            if let tabBar = view as? UITabBar { return tabBar }
            current = view.superview
        }
        return nil
    }
}
