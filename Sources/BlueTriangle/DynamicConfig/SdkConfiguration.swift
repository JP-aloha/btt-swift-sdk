//
//  SdkConfiguration.swift
//  blue-triangle
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

@objc
public final class SdkConfiguration: NSObject {
    @objc public let enableAllTracking: Bool
    @objc public let ignoreScreens: [String]
    @objc public let enableScreenTracking: Bool
    @objc public let networkSampleRateSDK: Double
    @objc public let enableGrouping: Bool
    @objc public let groupingIdleTime: Double
    @objc public let enableCrashTracking: Bool
    @objc public let enableANRTracking: Bool
    @objc public let enableMemoryWarning: Bool
    @objc public let enableLaunchTime: Bool
    @objc public let enableWebViewStitching: Bool
    @objc public let enableNetworkStateTracking: Bool
    @objc public let enableGroupingTapDetection: Bool
    @objc public let configKey: String
    @objc public let checkoutTrackingEnabled: Bool
    @objc public let checkoutClassName: [String]
    @objc public let checkoutURL: String
    @objc public let checkoutAmount: Double
    @objc public let checkoutCartCount: Int
    @objc public let checkoutCartCountCheckout: Int
    @objc public let checkoutOrderNumber: String
    @objc public let checkoutTimeValue: Int
    @objc public let ignoreBreadcrumbs: [String]
    @objc public let enableBreadcrumbs: Bool
    @objc public let enableAppInstall: Bool
    @objc public let enableForceRestart: Bool
    @objc public let forceRestartDuration: Double
    @objc public let enableScreenResponsiveness: Bool
    @objc public let fatalErrorSampleRate: Double
    @objc public let nonFatalErrorSampleRate: Double
    /// Per-session sampling decisions, so native and React Native sample the same session the same way.
    @objc public let shouldNetworkCapture: Bool
    @objc public let shouldReportFatalErrors: Bool
    @objc public let shouldReportNonFatalErrors: Bool

    init(session: SessionData, enableAllTracking: Bool) {
        self.enableAllTracking = enableAllTracking
        self.ignoreScreens = Array(session.ignoreViewControllers)
        self.enableScreenTracking = session.enableScreenTracking
        self.networkSampleRateSDK = session.networkSampleRate
        self.enableGrouping = session.enableGrouping
        self.groupingIdleTime = session.groupingIdleTime
        self.enableCrashTracking = session.enableCrashTracking
        self.enableANRTracking = session.enableANRTracking
        self.enableMemoryWarning = session.enableMemoryWarning
        self.enableLaunchTime = session.enableLaunchTime
        self.enableWebViewStitching = session.enableWebViewStitching
        self.enableNetworkStateTracking = session.enableNetworkStateTracking
        self.enableGroupingTapDetection = session.enableGroupingTapDetection
        self.configKey = session.configKey
        self.checkoutTrackingEnabled = session.checkoutTrackingEnabled
        self.checkoutClassName = session.checkoutClassName
        self.checkoutURL = session.checkoutURL
        self.checkoutAmount = session.checkoutAmount
        self.checkoutCartCount = session.checkoutCartCount
        self.checkoutCartCountCheckout = session.checkoutCartCountCheckout
        self.checkoutOrderNumber = session.checkoutOrderNumber
        self.checkoutTimeValue = session.checkoutTimeValue
        self.ignoreBreadcrumbs = Array(session.ignoreBreadcrumbs)
        self.enableBreadcrumbs = session.enableBreadcrumbs
        self.enableAppInstall = session.enableAppInstall
        self.enableForceRestart = session.enableForceRestart
        self.forceRestartDuration = session.forceRestartDuration
        self.enableScreenResponsiveness = session.enableScreenResponsiveness
        self.fatalErrorSampleRate = session.fatalErrorSampleRate
        self.nonFatalErrorSampleRate = session.nonFatalErrorSampleRate
        self.shouldNetworkCapture = session.shouldNetworkCapture
        self.shouldReportFatalErrors = session.shouldReportFatalErrors
        self.shouldReportNonFatalErrors = session.shouldReportNonFatalErrors
    }

    override public var description: String {
        "SdkConfiguration { enableAllTracking: \(enableAllTracking), ignoreScreens: \(ignoreScreens), enableScreenTracking: \(enableScreenTracking), networkSampleRateSDK: \(networkSampleRateSDK), enableGrouping: \(enableGrouping), groupingIdleTime: \(groupingIdleTime), enableCrashTracking: \(enableCrashTracking), enableANRTracking: \(enableANRTracking), enableMemoryWarning: \(enableMemoryWarning), enableLaunchTime: \(enableLaunchTime), enableWebViewStitching: \(enableWebViewStitching), enableNetworkStateTracking: \(enableNetworkStateTracking), enableGroupingTapDetection: \(enableGroupingTapDetection), configKey: \(configKey), checkoutTrackingEnabled: \(checkoutTrackingEnabled), checkoutClassName: \(checkoutClassName), checkoutURL: \(checkoutURL), checkoutAmount: \(checkoutAmount), checkoutCartCount: \(checkoutCartCount), checkoutCartCountCheckout: \(checkoutCartCountCheckout), checkoutOrderNumber: \(checkoutOrderNumber), checkoutTimeValue: \(checkoutTimeValue), ignoreBreadcrumbs: \(ignoreBreadcrumbs), enableBreadcrumbs: \(enableBreadcrumbs), enableAppInstall: \(enableAppInstall), enableForceRestart: \(enableForceRestart), forceRestartDuration: \(forceRestartDuration), enableScreenResponsiveness: \(enableScreenResponsiveness), fatalErrorSampleRate: \(fatalErrorSampleRate), nonFatalErrorSampleRate: \(nonFatalErrorSampleRate), shouldNetworkCapture: \(shouldNetworkCapture), shouldReportFatalErrors: \(shouldReportFatalErrors), shouldReportNonFatalErrors: \(shouldReportNonFatalErrors) }"
    }
}
