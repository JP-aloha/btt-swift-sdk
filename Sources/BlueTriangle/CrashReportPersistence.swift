//
//  CrashReportPersistence.swift
//
//  Created by Mathew Gacy on 7/7/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation
#if canImport(AppEventLogger)
import AppEventLogger
#endif

import MetricKit
import os


private let crashExceptionHandler: @convention(c) (NSException) -> Void = { exception in
    CrashReportPersistence.handleUncaughtException(exception)
}

enum CrashReportConfiguration {
    case nsException
}

struct CrashReportPersistence: CrashReportPersisting {
    private static let logger = BTLogger.live

    private static var persistence: Persistence? {
        guard let file = File.crashReport else {
            logger.error("Failed to get URL for `File.crashReport`.")
            return nil
        }
        return Persistence(fileManager: .default, file: file)
    }

    private static var path: String {
        persistence?.file.path ?? "MISSING"
    }

    static func configureCrashHandling(configuration: CrashReportConfiguration) {
        switch configuration {
        case .nsException:
            NSSetUncaughtExceptionHandler(crashExceptionHandler)
        }
    }
    
    static func handleUncaughtException(_ exception: NSException) {
        SignalHandler.disableCrashTracking()
        let crashID: String = UUID().uuidString
        let pageName: String = BlueTriangle.recentTimer()?.getPageName() ?? "Unknown"
        let crashSignpost = SignpostLogger(category: "\(crashID) - \(BlueTriangle.sessionID) + \(pageName)")
        crashSignpost.begin(name: Constants.crashSignpostName)
        crashSignpost.end(name: Constants.crashSignpostName)
        Self.save(
            CrashReport(sessionID: BlueTriangle.sessionID,
                        exception: exception,
                        pageName: BlueTriangle.recentTimer()?.getPageName(),
                        segment: BlueTriangle.recentTimer()?.getTrafficSegment(),
                        pageType: BlueTriangle.recentTimer()?.page.pageType,
                        nativeApp: CrashReportPersistence.nativeAppProperties()))
    }
    
    static func nativeAppProperties() -> NativeAppProperties {
        var nativeApp = NativeAppProperties.nstEmpty
        nativeApp.breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
        return nativeApp
    }
    
    static func disableExaptionHandler(){
        NSSetUncaughtExceptionHandler(nil)
    }

    static func save(_ crashReport: CrashReport) {
        do {
            try persistence?.save(crashReport)
        } catch {
            logger.error("Error saving \(crashReport) to \(path): \(error.localizedDescription)")
        }
    }

    static func read() -> CrashReport? {
        do {
            return try persistence?.read()
        } catch {
            logger.error("Error reading object at \(path): \(error.localizedDescription)")
            return nil
        }
    }

    static func clear() {
        do {
            try persistence?.clear()
        } catch {
            logger.error("Error clearing data at \(path): \(error.localizedDescription)")
        }
    }
    
}
/// Wraps MXMetricManager.makeLogHandle + mxSignpost to produce a custom
/// MXSignpostMetric entry in the next metric payload.
final class SignpostLogger {
    private let log: OSLog
    private var signpostID: OSSignpostID?

    init(category: String = "MatricKitPocDemo") {
        log = MXMetricManager.makeLogHandle(category: category)
    }

    func begin(name: StaticString = "MatricKitPocInterval") {
        let id = OSSignpostID(log: log)
        signpostID = id
        mxSignpost(.begin, log: log, name: name, signpostID: id)
    }

    func end(name: StaticString = "MatricKitPocInterval") {
        guard let id = signpostID else { return }
        mxSignpost(.end, log: log, name: name, signpostID: id)
        signpostID = nil
    }
}

