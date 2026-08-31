//
//  MetricKitWatchDog+DiagnosticProcessing.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
import Foundation
import MetricKit

@available(iOS 14.0, *)
extension MetricKitWatchDog {
    func processDiagnostics(_ payloads: [MXDiagnosticPayload], isLive: Bool) {
        guard let session = session() else {
            return
        }

        for payload in payloads {
 
            let isLive = isLive && (observingSince.map { payload.timeStampBegin >= $0 } ?? false)

            var hangCount = 0
            if #available(iOS 15.0, *) {
                hangCount = payload.hangDiagnostics?.count ?? 0
            }
            var appLaunchCount = 0
            if #available(iOS 16.0, *) {
                appLaunchCount = payload.appLaunchDiagnostics?.count ?? 0
            }
            logger.debug("MetricKit Watch Dog: payload from \(payload.timeStampBegin) to \(payload.timeStampEnd) - " +
                        "crash: \(payload.crashDiagnostics?.count ?? 0), " +
                        "hang: \(hangCount), " +
                        "cpuException: \(payload.cpuExceptionDiagnostics?.count ?? 0), " +
                        "diskWriteException: \(payload.diskWriteExceptionDiagnostics?.count ?? 0), " +
                        "appLaunch: \(appLaunchCount)")

            payload.crashDiagnostics?.forEach {
                logger.info("MetricKit Watch Dog: crash title = \(self.crashTitle(for: $0))")
                reportCrash($0, session: session, timeStampBegin: payload.timeStampBegin, timeStampEnd: payload.timeStampEnd)
            }
            payload.cpuExceptionDiagnostics?.forEach {
                let extraPairs = [
                    "totalCPUTime: \"\(measurementFormatter.string(from: $0.totalCPUTime))\"",
                    "totalSampledTime: \"\(measurementFormatter.string(from: $0.totalSampledTime))\""
                ]
                reportOrDefer($0, kind: .cpuException, summary: cpuExceptionSummary(for: $0), extraMetadataPairs: extraPairs, isLive: isLive, session: session, timeStampBegin: payload.timeStampBegin, timeStampEnd: payload.timeStampEnd)
            }
            payload.diskWriteExceptionDiagnostics?.forEach {
                let extraPairs = ["writesCaused: \"\(measurementFormatter.string(from: $0.totalWritesCaused))\""]
                reportOrDefer($0, kind: .diskWriteException, summary: diskWriteSummary(for: $0), extraMetadataPairs: extraPairs, isLive: isLive, session: session, timeStampBegin: payload.timeStampBegin, timeStampEnd: payload.timeStampEnd)
            }
            if #available(iOS 15.0, *) {
                payload.hangDiagnostics?.forEach {
                    let extraPairs = ["hangDuration: \"\(measurementFormatter.string(from: $0.hangDuration))\""]
                    reportOrDefer($0, kind: .hang, summary: hangSummary(for: $0), extraMetadataPairs: extraPairs, isLive: isLive, session: session, timeStampBegin: payload.timeStampBegin, timeStampEnd: payload.timeStampEnd)
                }
            }
            if #available(iOS 16.0, *) {
                payload.appLaunchDiagnostics?.forEach {
                    let extraPairs = ["launchDuration: \"\(measurementFormatter.string(from: $0.launchDuration))\""]
                    reportOrDefer($0, kind: .slowLaunch, summary: appLaunchSummary(for: $0), extraMetadataPairs: extraPairs, isLive: isLive, session: session, timeStampBegin: payload.timeStampBegin, timeStampEnd: payload.timeStampEnd)
                }
            }
        }
    }
}

// MARK: - Per-diagnostic summary text
@available(iOS 14.0, *)
extension MetricKitWatchDog {
    func cpuExceptionSummary(for diagnostic: MXCPUExceptionDiagnostic) -> String {
        "Excessive CPU usage detected, indicating that the app is consuming more CPU resources than expected, identified by Matric Kit"
    }

    func diskWriteSummary(for diagnostic: MXDiskWriteExceptionDiagnostic) -> String {
        "App encountered an excessive disk write exception, identified through Matric Kit"
    }

    private static let hangThresholdMilliseconds = 750

    @available(iOS 15.0, *)
    func hangSummary(for diagnostic: MXHangDiagnostic) -> String {
        "Potential app hang detected due to prolonged blocking of the main thread, identified by Matric Kit"
    }

    @available(iOS 16.0, *)
    func appLaunchSummary(for diagnostic: MXAppLaunchDiagnostic) -> String {
        "Slow app launch detected, indicating that the app took longer than expected to launch, detected through Matric Kit"
    }

    func crashTitle(for diagnostic: MXCrashDiagnostic) -> String {
        let signalLabel = signalName((diagnostic.signal)?.intValue) ?? "Crash"
        let appBinaryName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
        guard let tree = MXCallStackTreeJSON.decode(from: diagnostic.callStackTree.jsonRepresentation()),
              let frame = tree.crashedThreadFrame(preferringBinaryNamed: appBinaryName),
              let binaryName = frame.binaryName
        else { return signalLabel }

        let offsetHex = frame.offsetIntoBinaryTextSegment.map { String($0, radix: 16, uppercase: true) } ?? "0"
        return "\(signalLabel) in \(binaryName) + 0x\(offsetHex)"
    }

    private func signalName(_ number: Int?) -> String? {
        guard let number else { return nil }
        switch number {
        case 4: return "SIGILL"
        case 5: return "SIGTRAP"
        case 6: return "SIGABRT"
        case 8: return "SIGFPE"
        case 10: return "SIGBUS"
        case 11: return "SIGSEGV"
        default: return "Signal \(number)"
        }
    }
}

// MARK: - Crash report assembly
@available(iOS 14.0, *)
extension MetricKitWatchDog {
    func reportCrash(_ diagnostic: MXCrashDiagnostic, session: Session, timeStampBegin: Date, timeStampEnd: Date) {
        guard !hasFatalErrorSignpost(diagnostic) else {
            print("MetricKitWatchDog has FatalErrorSignpost, skipping")
            return
        }

        let (message, crashLocation) = crashStyleMessage(summary: crashSummary(for: diagnostic), callStackTree: diagnostic.callStackTree)

        var extraPairs = [String]()
        if let signal = diagnostic.signal?.intValue { extraPairs.append("signal: \(signal)") }
        if let exceptionCode = diagnostic.exceptionCode?.intValue { extraPairs.append("exceptionCode: \(exceptionCode)") }
        if let exceptionType = diagnostic.exceptionType?.intValue { extraPairs.append("exceptionType: \(exceptionType)") }
        let eMetadata = eMetadataString(diagnostic, title: crashLocation, extraPairs: extraPairs)

        if let pendingCrash = PendingCrashRecordStore.consume(matchingCrashTime: crashSignpostTime(from: diagnostic)) {
            uploadCrashReport(kind: .crash, sessionID: pendingCrash.sessionID, message: message,
                              pageName: pendingCrash.pageName, trafficSegment: pendingCrash.trafficSegment,
                              pageType: pendingCrash.pageType, breadcrumbs: pendingCrash.breadcrumbs,
                              eMetadata: eMetadata, eIdentifier: crashLocation,
                              session: session, timeStampBegin: timeStampBegin)
        } else if let timer = BlueTriangle.recentTimer() {
            Task {
                await errorMetricStore.addCrash(id: timer.uuid, message: message, eMetadata: eMetadata, eIdentifier: crashLocation, breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs())
            }
        } else {
            uploadCrashReport(kind: .crash, sessionID: BlueTriangle.sessionID, message: message,
                              pageName: nil, trafficSegment: nil, pageType: nil,
                              breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs(),
                              eMetadata: eMetadata, eIdentifier: crashLocation,
                              session: session, timeStampBegin: timeStampBegin)
        }
    }

    private func crashSummary(for diagnostic: MXCrashDiagnostic) -> String {
        let signo = diagnostic.signal?.intValue ?? 0
        let signalLabel = signalName(signo) ?? "Crash"
        let errno = diagnostic.exceptionCode?.intValue ?? 0
        let sigCode = diagnostic.exceptionType?.intValue ?? 0
        return "App crashed with \(signalLabel), signo: \(signo), errno: \(errno), signal code: \(sigCode), identified through Matric Kit"
    }
}

// MARK: - Report assembly (legacy)
@available(iOS 14.0, *)
extension MetricKitWatchDog {
    func reportOrDefer<D: MXDiagnostic & MXCallStackTreeProviding>(
        _ diagnostic: D,
        kind: MetricKitDiagnosticKind,
        summary: String,
        extraMetadataPairs: [String] = [],
        isLive: Bool,
        session: Session,
        timeStampBegin: Date,
        timeStampEnd: Date
    ) {
        let (message, location) = crashStyleMessage(summary: summary, callStackTree: diagnostic.callStackTree)
        let eMetadata = eMetadataString(diagnostic, title: location, extraPairs: extraMetadataPairs)

        guard isLive, let timer = BlueTriangle.recentTimer() else {
            uploadCrashReport(kind: kind, sessionID: BlueTriangle.sessionID, message: message,
                              pageName: nil, trafficSegment: nil, pageType: nil,
                              breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs(),
                              eMetadata: eMetadata, eIdentifier: location,
                              session: session, timeStampBegin: timeStampBegin)
            return
        }
        deferForPageSubmit(kind: kind,
                           uuid: timer.uuid,
                           message: message,
                           eMetadata: eMetadata,
                           eIdentifier: location,
                           breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs())
    }

    private func crashSignpostTime(from diagnostic: MXDiagnostic) -> UInt64? {
        guard #available(iOS 17.0, *),
              let record = diagnostic.signpostData?.first(where: { $0.name == String(describing: Constants.crashSignpostName) }),
              let crashTimeText = record.category.components(separatedBy: " - ").first
        else { return nil }
        return UInt64(crashTimeText)
    }

    private func hasFatalErrorSignpost(_ diagnostic: MXDiagnostic) -> Bool {
        guard #available(iOS 17.0, *) else { return false }
        return diagnostic.signpostData?.contains { $0.name == String(describing: Constants.externalFatalErrorSignpostName) } ?? false
    }
}

// MARK: - Deferred non-crash diagnostics (saved until the page they occurred on submits)
@available(iOS 14.0, *)
extension MetricKitWatchDog {
    private func deferForPageSubmit(kind: MetricKitDiagnosticKind, uuid: UUID, message: String, eMetadata: String, eIdentifier: String?, breadcrumbs: String?) {
        Task {
            switch kind {
            case .cpuException:
                await errorMetricStore.addCPUException(id: uuid, message: message, eMetadata: eMetadata, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .diskWriteException:
                await errorMetricStore.addDiskWriteException(id: uuid, message: message, eMetadata: eMetadata, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .hang:
                await errorMetricStore.addHang(id: uuid, message: message, eMetadata: eMetadata, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .slowLaunch:
                await errorMetricStore.addAppLaunch(id: uuid, message: message, eMetadata: eMetadata, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .crash:
                break // reportCrash() defers crash diagnostics itself, via errorMetricStore.addCrash().
            }
        }
    }

    /// Each of the five kinds that fired on this page gets its own beacon - none of them are merged
    /// together.
    func uploadPendingDiagnosticReports(pageName: String, uuid: UUID, segment: String, pageType: String) {
        Task {
            guard let session = session() else { return }
            if let metric = await errorMetricStore.flushCrash(id: uuid) {
                uploadPendingMetric(metric, kind: .crash, pageName: pageName, session: session, segment: segment, pageType: pageType)
            }
            if let metric = await errorMetricStore.flushHang(id: uuid) {
                uploadPendingMetric(metric, kind: .hang, pageName: pageName, session: session, segment: segment, pageType: pageType)
            }
            if let metric = await errorMetricStore.flushCPUException(id: uuid) {
                uploadPendingMetric(metric, kind: .cpuException, pageName: pageName, session: session, segment: segment, pageType: pageType)
            }
            if let metric = await errorMetricStore.flushDiskWriteException(id: uuid) {
                uploadPendingMetric(metric, kind: .diskWriteException, pageName: pageName, session: session, segment: segment, pageType: pageType)
            }
            if let metric = await errorMetricStore.flushAppLaunch(id: uuid) {
                uploadPendingMetric(metric, kind: .slowLaunch, pageName: pageName, session: session, segment: segment, pageType: pageType)
            }
        }
    }

    private func uploadPendingMetric(_ metric: ErrorMetric, kind: MetricKitDiagnosticKind, pageName: String, session: Session, segment: String, pageType: String) {
        var nativeApp = NativeAppProperties.nstEmpty
        nativeApp.breadcrumbs = metric.breadcrumbs
        nativeApp.eMetadata = metric.eMetadata
        nativeApp.eIdentifier = metric.eIdentifier
        let crashReport = CrashReport(errorType: kind.errorType,
                                      sessionID: session.sessionID,
                                      message: metric.message,
                                      eCount: metric.eCount,
                                      pageName: pageName,
                                      segment: segment,
                                      pageType: pageType,
                                      nativeApp: nativeApp,
                                      intervalProvider: metric.time)
        uploadReportOnly(session: session, report: crashReport, pageName: pageName, segment: segment, pageType: pageType, event: kind.event)
    }
}

// MARK: - Shared crash-style message assembly
@available(iOS 14.0, *)
private extension MetricKitWatchDog {
    func crashStyleMessage(summary: String, callStackTree: MXCallStackTree) -> (message: String, location: String?) {
        let appBinaryName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
        let tree = MXCallStackTreeJSON.decode(from: callStackTree.jsonRepresentation())
        let location = tree?.crashedThreadFrame(preferringBinaryNamed: appBinaryName)?.formattedCrashLocation()

        var lines = [summary]
        if let location {
            lines.append(location)
        }
        lines.append(" ")
        lines.append(tree?.formattedStackTrace() ?? "Call stack unavailable")
        return (lines.joined(separator: "\n"), location)
    }
}

// MARK: - Shared mk_matadata assembly
@available(iOS 14.0, *)
private extension MetricKitWatchDog {
    func eMetadataString(_ diagnostic: MXDiagnostic, title: String?, extraPairs: [String]) -> String {
        var pairs = [String]()
        if let title {
            pairs.append("title: \"\(title)\"")
        }
        pairs.append(contentsOf: extraPairs)
        pairs.append("appVersion: \"\(diagnostic.applicationVersion)\"")
        pairs.append("appBuildVersion: \"\(diagnostic.metaData.applicationBuildVersion)\"")
        pairs.append("osVersion: \"\(diagnostic.metaData.osVersion)\"")
        pairs.append("deviceType: \"\(diagnostic.metaData.deviceType)\"")
        pairs.append("platformArchitecture: \"\(diagnostic.metaData.platformArchitecture)\"")
        pairs.append("regionFormat: \"\(diagnostic.metaData.regionFormat)\"")
        if #available(iOS 17.0, *) {
            pairs.append("isTestFlightApp: \(diagnostic.metaData.isTestFlightApp)")
            pairs.append("lowPowerModeEnabled: \(diagnostic.metaData.lowPowerModeEnabled)")
        }
        return "[\(pairs.joined(separator: ", "))]"
    }
}
#endif
