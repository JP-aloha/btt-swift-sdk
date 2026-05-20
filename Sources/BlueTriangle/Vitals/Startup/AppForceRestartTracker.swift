//
//  AppForceRestartTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/05/26.
//

import Foundation
import UIKit

public final class AppForceRestartTracker {

    private let logger: Logging
    private let forceRestartReporter: AppForceRestartReporter
    private let store = BTTActivityStore()

    // MARK: - Init
    init( _ forceRestartReporter: AppForceRestartReporter, _ logger: Logging) {
        self.forceRestartReporter = forceRestartReporter
        self.logger = logger
        registerLifecycle()
        checkForceRestart()
    }
}

// MARK: - Force Restart Detection

extension AppForceRestartTracker {

    private func checkForceRestart() {
        checkForceKill()
    }

    private func checkForceKill() {
        defer { store.clear() }
        guard let result = store.get() else { return }
        let diff = Date().timeIntervalSince(result.date)
        if diff < 10 {
            trackForceKill(diff, result)
        }
    }

    private func trackForceKill( _ at: TimeInterval, _ activity: ActivityRecord) {
        forceRestartReporter.reportForceRestartForPage(activity)
        logger.info("Force kill detected on page '\(activity.pageName) - \(activity.trafficSegment) - \(activity.pageType)' (relaunch in \(at) sec)")
    }
}

// MARK: - Lifecycle Registration

extension AppForceRestartTracker {

    private func registerLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
}

// MARK: - Lifecycle Events

extension AppForceRestartTracker {

    @objc
    private func appWillResignActive() {
        store.updatePageDetail()
    }

    @objc
    private func appDidEnterBackground() {
        store.updatePageDetail()
        BlueTriangle.saveBreadcrumbsToDisk()
    }

    @objc
    private func appWillTerminate() {
        store.updatePageDetail()
        BlueTriangle.saveBreadcrumbsToDisk()
        store.save()
    }
}
