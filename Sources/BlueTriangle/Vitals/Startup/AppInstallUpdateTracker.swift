//
//  AppInstallUpdateTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/05/26.
//

import Foundation
import UIKit

public final class AppInstallUpdateTracker {

    public enum LaunchType: Equatable {
        case firstInstall(version: String)
        case update(oldVersion: String, newVersion: String)
        case normalLaunch(version: String)
    }

    private let logger: Logging
    private let appInstallReporter: AppInstallReporter
    private let userDefaults: UserDefaults
    private let versionKey = "com.bluetriangle.app.version"
    private var appInstallTime: Date?
    private var oldVersion: String?
    private var newVersion: String?

    // MARK: - Init
    init(_ appInstallReporter: AppInstallReporter, _ logger: Logging, _ userDefaults: UserDefaults = .standard) {
        self.appInstallReporter = appInstallReporter
        self.logger = logger
        self.userDefaults = userDefaults

        let result = detect()
        handle(result)
    }
}

// MARK: - Detection

extension AppInstallUpdateTracker {
    
    private func detect() -> LaunchType {
        let currentVersion = Bundle.main.releaseVersionNumber ?? "0.0"
        guard let previousVersion = userDefaults.string(forKey: versionKey) else {
            let installDate = getAppInstallTimeFromBundle()
            let days = Date().timeIntervalSince(installDate)
            let threeDays: TimeInterval = 3 * 24 * 60 * 60
            userDefaults.set(currentVersion, forKey: versionKey)
            
            // Fresh install
            if days < threeDays {
                return .firstInstall(version: currentVersion)
            }
            // Existing app upgraded to SDK version
            return .normalLaunch(version: currentVersion)
        }
        
        if previousVersion.compare(currentVersion, options: .numeric) == .orderedAscending {
            userDefaults.set(currentVersion, forKey: versionKey)
            return .update(
                oldVersion: previousVersion,
                newVersion: currentVersion
            )
        }
        
        return .normalLaunch(version: currentVersion)
    }

    private func handle(_ event: LaunchType) {
        switch event {

        case .firstInstall(let version):
            trackInstall(version: version)

        case .update(let old, let new):
            trackUpdate(old: old, new: new)

        case .normalLaunch:
            logger.info("App normal launch")
        }
    }
}

// MARK: - Tracking

extension AppInstallUpdateTracker {

    private func trackInstall(version: String) {
        newVersion = version
        appInstallTime = self.getAppInstallTimeFromBundle()
        logger.info("App installed \(version) at \(self.appInstallTime ?? Date())")
    }

    private func trackUpdate(old: String, new: String) {
        oldVersion = old
        newVersion = new
        if let old = oldVersion, let new = newVersion { BlueTriangle.collectBreadcrumb(AppUpdateEvent(from: old, to: new)) }
        logger.info("App Updated from \(old) → \(new) at \(self.getAppInstallTimeFromBundle()) - current - \(Date())")
    }

    internal func reportAppInstall() {
        guard let installTime = self.appInstallTime else { return }
        appInstallReporter.reportAppInstallEvent(installTime)
        if let version = newVersion { BlueTriangle.collectBreadcrumb(AppInstallEvent(version: version)) }
        self.appInstallTime = nil
    }
}

// MARK: - Helpers

extension AppInstallUpdateTracker {
    
    private func getAppInstallTimeFromBundle() -> Date {
        guard let url = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first else {
            return Date()
        }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date ?? Date()
    }
}
