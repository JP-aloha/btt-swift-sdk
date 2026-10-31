//
//  BTTScreenTracker.swift
//
//
//  Created by Ashok Singh on 06/11/23.
//

import Foundation

@preconcurrency
public final class BTTScreenTracker {
    
    private let lock = NSLock()
    private var hasViewing = false
    private var id = "\(Identifier.random())"
    private var pageName: String
    private var tracker: BTTScreenLifecycleTracker?
    private var type = ScreenType.Manual
    
    public init(_ screenName: String, type : ScreenType = .Manual) {
        self.type = type
        self.pageName = screenName
        self.tracker = BlueTriangle.screenTracker
    }

    // MARK: - Private
    
    private func updateScreenType() {
        if type == ScreenType.UIKit {
            tracker?.setUpScreenType(.UIKit)
        } else if type == ScreenType.SwiftUI {
            tracker?.setUpScreenType(.SwiftUI)
        } else if type == ScreenType.ReactNative {
            tracker?.setUpScreenType(.ReactNative)
        } else {
            tracker?.setUpScreenType(.Manual)
        }
    }
    
    public func loadStarted() {
        lock.sync {
            hasViewing = true
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .load)
        }
    }
    
    public func loadEnded() {
        lock.sync {
            guard hasViewing else { return }
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .finish)
        }
    }

    public func viewStart() {
        lock.sync {
            hasViewing = true
            updateScreenType()
            tracker?.manageTimer(pageName, id: id, type: .view)
            reportAppearBreadcrumb()
        }
    }
    
    public func viewingEnd() {
        lock.sync {
            guard hasViewing else { return }
            tracker?.manageTimer(pageName, id: id, type: .disappear)
            hasViewing = false
            reportDisappearBreadcrumb()
        }
    }
    
    private func reportAppearBreadcrumb(){
        if type == ScreenType.ReactNative {
            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onAppear, className: pageName))
        }
    }
    
    private func reportDisappearBreadcrumb(){
        if type == ScreenType.ReactNative {
            BlueTriangle.collectBreadcrumb(UILifecycleEvent(event: Constants.Breadcrums.UILifeCycle.onDisappear, className: pageName))
        }
    }
}

