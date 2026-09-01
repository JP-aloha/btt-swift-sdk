//
//  ErrorMetricStore.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/01/26.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

public actor ErrorMetricStore {

    private var anrs: [UUID: ErrorMetric] = [:]
    private var memoryWarnings: [UUID: ErrorMetric] = [:]
    private var errors: [UUID: ErrorMetric] = [:]
    private var cpuExceptions: [UUID: ErrorMetric] = [:]
    private var diskWriteExceptions: [UUID: ErrorMetric] = [:]
    private var hangs: [UUID: ErrorMetric] = [:]
    private var appLaunches: [UUID: ErrorMetric] = [:]
    private var crashes: [UUID: ErrorMetric] = [:]

    // MARK: - Add

    func addAnrError(id: UUID, message: String, breadcrumbs: String?) {
        if let current = anrs[id] {
            anrs[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: 1,
                breadcrumbs: breadcrumbs
            )
        } else {
            anrs[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: 1,
                breadcrumbs: breadcrumbs
            )
        }
    }

    func addMemoryWarning(id: UUID, message: String, breadcrumbs: String?) {
        if let current = memoryWarnings[id] {
            memoryWarnings[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: 1,
                breadcrumbs: breadcrumbs
            )
        } else {
            memoryWarnings[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: 1,
                breadcrumbs: breadcrumbs
            )
        }
    }

    func addError(id: UUID, message: String, line: UInt = 1, breadcrumbs: String?) {
        if let current = errors[id] {
            errors[id] = ErrorMetric(
                message: current.message,
                eCount: current.eCount + 1,
                line: line,
                breadcrumbs: breadcrumbs
            )
        } else {
            errors[id] = ErrorMetric(
                message: message,
                eCount: 1,
                line: line,
                breadcrumbs: breadcrumbs
            )
        }
    }

    func addCPUException(id: UUID, message: String, stackTrace: String?, eMetadata: String?, eIdentifier: String?, breadcrumbs: String?) {
        if let current = cpuExceptions[id] {
            cpuExceptions[id] = ErrorMetric(message: current.message, eCount: current.eCount + 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: current.eMetadata, eIdentifier: current.eIdentifier, stackTrace: current.stackTrace)
        } else {
            cpuExceptions[id] = ErrorMetric(message: message, eCount: 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: eMetadata, eIdentifier: eIdentifier, stackTrace: stackTrace)
        }
    }

    func addDiskWriteException(id: UUID, message: String, stackTrace: String?, eMetadata: String?, eIdentifier: String?, breadcrumbs: String?) {
        if let current = diskWriteExceptions[id] {
            diskWriteExceptions[id] = ErrorMetric(message: current.message, eCount: current.eCount + 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: current.eMetadata, eIdentifier: current.eIdentifier, stackTrace: current.stackTrace)
        } else {
            diskWriteExceptions[id] = ErrorMetric(message: message, eCount: 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: eMetadata, eIdentifier: eIdentifier, stackTrace: stackTrace)
        }
    }

    func addHang(id: UUID, message: String, stackTrace: String?, eMetadata: String?, eIdentifier: String?, breadcrumbs: String?) {
        if let current = hangs[id] {
            hangs[id] = ErrorMetric(message: current.message, eCount: current.eCount + 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: current.eMetadata, eIdentifier: current.eIdentifier, stackTrace: current.stackTrace)
        } else {
            hangs[id] = ErrorMetric(message: message, eCount: 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: eMetadata, eIdentifier: eIdentifier, stackTrace: stackTrace)
        }
    }

    func addAppLaunch(id: UUID, message: String, stackTrace: String?, eMetadata: String?, eIdentifier: String?, breadcrumbs: String?) {
        if let current = appLaunches[id] {
            appLaunches[id] = ErrorMetric(message: current.message, eCount: current.eCount + 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: current.eMetadata, eIdentifier: current.eIdentifier, stackTrace: current.stackTrace)
        } else {
            appLaunches[id] = ErrorMetric(message: message, eCount: 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: eMetadata, eIdentifier: eIdentifier, stackTrace: stackTrace)
        }
    }

    // Crash diagnostics only land here when there's no PendingCrashRecord match but a page is
    // currently running - see MetricKitWatchDog+DiagnosticProcessing.reportCrash().
    func addCrash(id: UUID, message: String, stackTrace: String?, eMetadata: String?, eIdentifier: String?, breadcrumbs: String?) {
        if let current = crashes[id] {
            crashes[id] = ErrorMetric(message: current.message, eCount: current.eCount + 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: current.eMetadata, eIdentifier: current.eIdentifier, stackTrace: current.stackTrace)
        } else {
            crashes[id] = ErrorMetric(message: message, eCount: 1, line: 1, breadcrumbs: breadcrumbs, eMetadata: eMetadata, eIdentifier: eIdentifier, stackTrace: stackTrace)
        }
    }

    // MARK: - Flush (get + remove)
    func flushAnrError(id: UUID) -> ErrorMetric? {
        anrs.removeValue(forKey: id)
    }

    func flushMemoryWarning(id: UUID) -> ErrorMetric? {
        memoryWarnings.removeValue(forKey: id)
    }

    func flushError(id: UUID) -> ErrorMetric? {
        errors.removeValue(forKey: id)
    }

    func flushCPUException(id: UUID) -> ErrorMetric? {
        cpuExceptions.removeValue(forKey: id)
    }

    func flushDiskWriteException(id: UUID) -> ErrorMetric? {
        diskWriteExceptions.removeValue(forKey: id)
    }

    func flushHang(id: UUID) -> ErrorMetric? {
        hangs.removeValue(forKey: id)
    }

    func flushAppLaunch(id: UUID) -> ErrorMetric? {
        appLaunches.removeValue(forKey: id)
    }

    func flushCrash(id: UUID) -> ErrorMetric? {
        crashes.removeValue(forKey: id)
    }
}

struct ErrorMetric {
    let message: String
    let eCount: Int
    let line: UInt
    let breadcrumbs: String?
    let time = Date().timeIntervalSince1970
    var eMetadata: String?
    var eIdentifier: String?
    var stackTrace: String?
}
