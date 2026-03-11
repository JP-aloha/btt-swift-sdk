//
//  AppInstallTracker.swift
//  blue-triangle
//
//  Created by Ashok Singh on 27/02/26.
//
import Foundation

public class AppInstallTracker {
    
    public enum LaunchType: Equatable {
        case firstInstall(version: String)
        case update(oldVersion: String, newVersion: String)
        case normalLaunch(version: String)
    }
    
    private let logger: Logging
    private let userDefaults: UserDefaults
    private let versionKey = "com.bluetriangle.app.version"
    
    // MARK: - Init (Auto Trigger)
    init(logger : Logging, userDefaults: UserDefaults = .standard) {
        self.logger = logger
        self.userDefaults = userDefaults
        let result = detect()
        handle(result)
    }
    
    // MARK: - Detection
    
    private func detect() -> LaunchType {
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
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
            logger.info("App normal launch")
            break
        }
    }
    
    // MARK: - Tracking (Override or Modify)
    open func trackInstall(version: String) {
        BlueTriangle.collectBreadcrumb(AppInstallEvent(event: "AppInstall", version: version))
        logger.info("App Installed with version: \(version)")
    }
    
    open func trackUpdate(old: String, new: String) {
        BlueTriangle.collectBreadcrumb(AppUpdateEvent(event: "AppUpdate", fromVersion: old , toVersion: new))
        logger.info("App Updated from \(old) → \(new)")
    }
}
