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
            NSSetUncaughtExceptionHandler { exception in
                SignalHandler.disableCrashTracking()
                Self.save(
                    CrashReport(sessionID: BlueTriangle.sessionID,
                                exception: exception, pageName: BlueTriangle.recentTimer()?.page.pageName))
            }
        }
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
    
    static func saveCrash(crashReport: CrashReport) {
        do {
            try persistence?.save(crashReport)
        } catch {
            logger.error("Error saving \(crashReport) to \(path): \(error.localizedDescription)")
        }
    }
}
