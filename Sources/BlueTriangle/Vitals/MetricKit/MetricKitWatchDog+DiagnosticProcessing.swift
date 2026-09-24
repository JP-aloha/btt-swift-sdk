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
        "Excessive CPU usage detected, indicating that the app is consuming more CPU resources than expected."
    }

    func diskWriteSummary(for diagnostic: MXDiskWriteExceptionDiagnostic) -> String {
        "App encountered an excessive disk write exception."
    }

    private static let hangThresholdMilliseconds = 750

    @available(iOS 15.0, *)
    func hangSummary(for diagnostic: MXHangDiagnostic) -> String {
        "Potential app hang detected due to prolonged blocking of the main thread."
    }

    @available(iOS 16.0, *)
    func appLaunchSummary(for diagnostic: MXAppLaunchDiagnostic) -> String {
        "Slow app launch detected, indicating that the app took longer than expected to launch"
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

        let (message, flattenedStackTrace, crashLocation) = crashStyleMessage(summary: crashSummary(for: diagnostic), callStackTree: diagnostic.callStackTree)
        let stackTrace = structuredStackTrace(for: diagnostic) ?? flattenedStackTrace

        var extraPairs = [String]()
        if let signal = diagnostic.signal?.intValue { extraPairs.append("signal: \(signal)") }
        if let exceptionCode = diagnostic.exceptionCode?.intValue { extraPairs.append("exceptionCode: \(exceptionCode)") }
        if let exceptionType = diagnostic.exceptionType?.intValue { extraPairs.append("exceptionType: \(exceptionType)") }
        let eMeta = eMetaString(diagnostic, extraPairs: extraPairs)

        if let pendingCrash = PendingCrashRecordStore.consume(matchingCrashTime: crashSignpostTime(from: diagnostic)) {
            uploadCrashReport(kind: .crash, sessionID: pendingCrash.sessionID, message: message, stackTrace: stackTrace,
                              pageName: pendingCrash.pageName, trafficSegment: pendingCrash.trafficSegment,
                              pageType: pendingCrash.pageType, breadcrumbs: pendingCrash.breadcrumbs,
                              eMeta: eMeta, eIdentifier: crashLocation,
                              session: session, timeStampBegin: timeStampBegin)
        } else if let timer = BlueTriangle.recentTimer() {
            timer.setEvent(BTTEvents.nativeAppCrash)
            Task {
                await errorMetricStore.addCrash(id: timer.uuid, message: message, stackTrace: stackTrace, eMeta: eMeta, eIdentifier: crashLocation, breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs())
            }
        } else {
            uploadCrashReport(kind: .crash, sessionID: BlueTriangle.sessionID, message: message, stackTrace: stackTrace,
                              pageName: nil, trafficSegment: nil, pageType: nil,
                              breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs(),
                              eMeta: eMeta, eIdentifier: crashLocation,
                              session: session, timeStampBegin: timeStampBegin)
        }
    }

    /// Structured (JSON-string) stack trace for a crash diagnostic - nil if the call stack tree
    /// can't be decoded or has no call stacks, in which case reportCrash() falls back to the
    /// flattened plain-text format.
    private func structuredStackTrace(for diagnostic: MXCrashDiagnostic) -> String? {
        guard let tree = MXCallStackTreeJSON.decode(from: diagnostic.callStackTree.jsonRepresentation()) else {
            return nil
        }
        return tree.buildStructuredStackTrace()
    }

    private func crashSummary(for diagnostic: MXCrashDiagnostic) -> String {
        let signalLabel = signalName(diagnostic.signal?.intValue) ?? "an unknown signal"
        let exceptionLabel = exceptionTypeName(diagnostic.exceptionType?.intValue) ?? "an unknown exception"
        return "App crashed with \(exceptionLabel) (\(signalLabel))."
    }

    /// Mach exception type (`<mach/exception_types.h>`), not the POSIX signal - this is what a
    /// standard crash log's "Exception Type" line names (e.g. EXC_BAD_ACCESS for a SIGSEGV).
    private func exceptionTypeName(_ number: Int?) -> String? {
        guard let number else { return nil }
        switch number {
        case 1: return "EXC_BAD_ACCESS"
        case 2: return "EXC_BAD_INSTRUCTION"
        case 3: return "EXC_ARITHMETIC"
        case 4: return "EXC_EMULATION"
        case 5: return "EXC_SOFTWARE"
        case 6: return "EXC_BREAKPOINT"
        case 10: return "EXC_CRASH"
        case 11: return "EXC_RESOURCE"
        case 12: return "EXC_GUARD"
        default: return "Exception \(number)"
        }
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
        let (message, stackTrace, location) = crashStyleMessage(summary: summary, callStackTree: diagnostic.callStackTree)
        let eMeta = eMetaString(diagnostic, extraPairs: extraMetadataPairs)

        guard isLive, let timer = BlueTriangle.recentTimer() else {
            uploadCrashReport(kind: kind, sessionID: BlueTriangle.sessionID, message: message, stackTrace: stackTrace,
                              pageName: nil, trafficSegment: nil, pageType: nil,
                              breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs(),
                              eMeta: eMeta, eIdentifier: location,
                              session: session, timeStampBegin: timeStampBegin)
            return
        }
        timer.setEvent(kind.event)
        deferForPageSubmit(kind: kind,
                           uuid: timer.uuid,
                           message: message,
                           stackTrace: stackTrace,
                           eMeta: eMeta,
                           eIdentifier: location,
                           breadcrumbs: BlueTriangle.breadcrumbManager?.breadcrumbs())
    }

    /// The signal-crash path's signpost category leads with `time(NULL)` (seconds since epoch) - convert
    /// to milliseconds to match `PendingCrashRecord.crashTime`'s convention.
    private func crashSignpostTime(from diagnostic: MXDiagnostic) -> Millisecond? {
        guard #available(iOS 17.0, *),
              let record = diagnostic.signpostData?.first(where: { $0.name == String(describing: Constants.crashSignpostName) }),
              let crashTimeText = record.category.components(separatedBy: " - ").first,
              let crashTimeSeconds = Millisecond(crashTimeText)
        else { return nil }
        return crashTimeSeconds * 1000
    }

    private func hasFatalErrorSignpost(_ diagnostic: MXDiagnostic) -> Bool {
        guard #available(iOS 17.0, *) else { return false }
        return diagnostic.signpostData?.contains { $0.name == String(describing: Constants.externalFatalErrorSignpostName) } ?? false
    }
}

// MARK: - Deferred non-crash diagnostics (saved until the page they occurred on submits)
@available(iOS 14.0, *)
extension MetricKitWatchDog {
    private func deferForPageSubmit(kind: MetricKitDiagnosticKind, uuid: UUID, message: String, stackTrace: String?, eMeta: String, eIdentifier: String?, breadcrumbs: String?) {
        Task {
            switch kind {
            case .cpuException:
                await errorMetricStore.addCPUException(id: uuid, message: message, stackTrace: stackTrace, eMeta: eMeta, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .diskWriteException:
                await errorMetricStore.addDiskWriteException(id: uuid, message: message, stackTrace: stackTrace, eMeta: eMeta, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .hang:
                await errorMetricStore.addHang(id: uuid, message: message, stackTrace: stackTrace, eMeta: eMeta, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
            case .slowLaunch:
                await errorMetricStore.addAppLaunch(id: uuid, message: message, stackTrace: stackTrace, eMeta: eMeta, eIdentifier: eIdentifier, breadcrumbs: breadcrumbs)
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
        nativeApp.eMeta = metric.eMeta
        nativeApp.eIdentifier = metric.eIdentifier
        nativeApp.stackTrace = metric.stackTrace
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
    /// `message` is just the summary and (if known) the crash location - at most two lines. The actual
    /// call stack goes in `stackTrace` instead, flattened to a single line (its own newlines replaced
    /// with spaces) rather than embedded in `message` alongside everything else.
    func crashStyleMessage(summary: String, callStackTree: MXCallStackTree) -> (message: String, stackTrace: String?, location: String?) {
        let appBinaryName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String
        let tree = MXCallStackTreeJSON.decode(from: callStackTree.jsonRepresentation())
        let crashLocation = tree?.crashedThreadFrame(preferringBinaryNamed: appBinaryName)?.formattedCrashLocation()

        var messageLines = [summary]
        if let crashLocation {
            messageLines.append(crashLocation)
        }
        let message = messageLines.joined(separator: "\n")

        let stackTraceText = tree?.formattedStackTrace() ?? "Call stack unavailable"
        let stackTrace = stackTraceText
            .components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .joined(separator: Constants.crashReportLineSeparator)

        return (message, stackTrace.isEmpty ? nil : stackTrace, crashLocation)
    }
}

// MARK: - Shared mk_matadata assembly
@available(iOS 14.0, *)
private extension MetricKitWatchDog {
    func eMetaString(_ diagnostic: MXDiagnostic, extraPairs: [String]) -> String {
        var allExtraPairs = extraPairs
        allExtraPairs.append("regionFormat: \"\(diagnostic.metaData.regionFormat)\"")
        if #available(iOS 17.0, *) {
            allExtraPairs.append("isTestFlightApp: \(diagnostic.metaData.isTestFlightApp)")
            allExtraPairs.append("lowPowerModeEnabled: \(diagnostic.metaData.lowPowerModeEnabled)")
        }
        return EMetaBuilder.build(
            source: .metricKit,
            build: diagnostic.metaData.applicationBuildVersion,
            arch: diagnostic.metaData.platformArchitecture,
            extraPairs: allExtraPairs)
    }
}
#endif
