//
//  AppInstallTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 27/02/26.
//
import Foundation
import UIKit

public class AppStartupTracker {
    
    public enum LaunchType: Equatable {
        case firstInstall(version: String)
        case update(oldVersion: String, newVersion: String)
        case normalLaunch(version: String)
    }
    
    private let logger: Logging
    private let appInstallReporter : AppInstallReporter
    private let forceKillReporter : ForceRestartReporter
    private let store = BTTActivityStore()
    private var appInstallTime: Date?
    private let userDefaults: UserDefaults
    private let versionKey = "com.bluetriangle.app.version"
    
    // MARK: - Init
    init(_ appInstall: AppInstallReporter, _ forceKillReporter: ForceRestartReporter, _ logger: Logging, _ userDefaults: UserDefaults = .standard) {
        self.appInstallReporter = appInstall
        self.forceKillReporter = forceKillReporter
        self.logger = logger
        self.userDefaults = userDefaults
        self.registerLifecycle()
        let result = detect()
        handle(result)
    }
    
    // MARK: - Detection
    private func detect() -> LaunchType {
        let currentVersion =  Bundle.main.releaseVersionNumber ?? "0.0"
        guard let previousVersion = userDefaults.string(forKey: versionKey) else {
            userDefaults.set(currentVersion, forKey: versionKey)
            return .firstInstall(version: currentVersion)
        }
        if previousVersion.compare(currentVersion, options: .numeric) == .orderedAscending {
            userDefaults.set(currentVersion, forKey: versionKey)
            return .update(oldVersion: previousVersion, newVersion: currentVersion)
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
            checkForceKill()
            logger.info("App normal launch")
        }
    }
}

// MARK: - Tracking
extension AppStartupTracker {

    func trackInstall(version: String) {
        appInstallTime = self.getAppInstallTimeFromBundle()
        BlueTriangle.collectBreadcrumb(AppInstallEvent(version: version))
        logger.info("App installed \(version) at \(self.appInstallTime ?? Date())")
    }
    
    func trackUpdate(old: String, new: String) {
        BlueTriangle.collectBreadcrumb(AppUpdateEvent(from: old, to: new))
        logger.info("App Updated from \(old) → \(new) at \(self.getAppInstallTimeFromBundle()) - current - \(Date())")
    }
    
    func trackForceKill(_ at : TimeInterval, _ activity : ActivityRecord) {
        forceKillReporter.reportForceRestartForPage(activity)
        logger.info("Force kill detected on page '\(activity.pageName) - \(activity.trafficSegment) - \(activity.pageType)' (relaunch in \(at) sec)")
    }
    
    func reportAppInstall() {
        guard  let installTime = self.appInstallTime else { return }
        appInstallReporter.reportAppInstallEvent(installTime)
        self.appInstallTime = nil
    }
    
    private func checkForceKill() {
        defer { store.clear() }
        guard let result = store.get() else { return }
        let diff = Date().timeIntervalSince(result.date)
        if diff < 10 { trackForceKill(diff, result) }
    }
}

// MARK: - Lifecycle
extension AppStartupTracker {
    private func registerLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc private func appWillResignActive() {
        store.updatePageName()
    }
    
    @objc private func appDidEnterBackground() {
        store.updatePageName()
    }
 
    @objc private func appWillTerminate() {
        store.updatePageName()
        store.save()
    }
}

// MARK: - Helpers
extension AppStartupTracker {
    private func getAppInstallTimeFromBundle() -> Date {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: Bundle.main.bundlePath) else {
            return Date()
        }
        return attributes[.creationDate] as? Date ?? Date()
    }
}

class BTTActivityStore {
    private let queue = DispatchQueue(label: "com.bluetriangle.activitystore")
    private let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    private let prefix = "bttlt_"
    private let separator = "~"
    private var pageName = Constants.APP_INSTALL_PAGE_GROUP
    private var trafficSegment = Constants.defaultTraficSegment
    private var pageType = Constants.defaultPageType

    // MARK: - Public
    func updatePageName() {
        queue.async {
            guard let timer = BlueTriangle.recentTimer() else { return }
            let name    = timer.getPageName()
            let segment = timer.getTrafficSegment()
            let type    = timer.page.pageType
            if !name.isEmpty    { self.pageName       = name }
            if !segment.isEmpty { self.trafficSegment = segment }
            if !type.isEmpty    { self.pageType       = type }
        }
    }

    func save() {
        // sync — must complete before process exits on terminate
        queue.sync {
            self.deleteExisting()
            let ts       = Int64(Date().timeIntervalSince1970 * 1000)
            // Format: bttlt_<ts>~<pageName>~<trafficSegment>~<pageType>
            let filename = "\(self.prefix)\(ts)\(self.separator)\(self.pageName)\(self.separator)\(self.trafficSegment)\(self.separator)\(self.pageType)"
            let url      = self.dir.appendingPathComponent(filename)
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
    }

    func get() -> ActivityRecord? {
        queue.sync {
            guard let filename = try? FileManager.default
                .contentsOfDirectory(atPath: dir.path)
                .first(where: { $0.hasPrefix(self.prefix) }) else { return nil }

            // Strip prefix → "<ts>~<pageName>~<trafficSegment>~<pageType>"
            let stripped = String(filename.dropFirst(self.prefix.count))
            let parts    = stripped.components(separatedBy: self.separator)
            guard parts.count >= 4, let ts = TimeInterval(parts[0]) else { return nil }

            return ActivityRecord(
                date:           Date(timeIntervalSince1970: ts / 1000),
                pageName:       parts[1],
                trafficSegment: parts[2],
                pageType:       parts[3]
            )
        }
    }

    func clear() {
        queue.async { self.deleteExisting() }
    }

    // MARK: - Private

    private func deleteExisting() {
        guard let files = try? FileManager.default
            .contentsOfDirectory(atPath: dir.path)
            .filter({ $0.hasPrefix(self.prefix) }) else { return }
        files.forEach {
            try? FileManager.default.removeItem(at: self.dir.appendingPathComponent($0))
        }
    }
}

// MARK: - Model
struct ActivityRecord {
    let date:           Date
    let pageName:       String
    let trafficSegment: String
    let pageType:       String
}
