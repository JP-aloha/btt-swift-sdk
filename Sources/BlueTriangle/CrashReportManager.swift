//
//  CrashReportManager.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final class CrashReportManager: CrashReportManaging {

    private let errorMetricStore = ErrorMetricStore()

    private let crashReportPersistence: CrashReportPersisting.Type

    private let logger: Logging

    private let uploader: Uploading

    private let session: SessionProvider

    private let intervalProvider: () -> TimeInterval

    /// Delays uploading a fatal error saved by `logFatalError()` until `session()` has a session to
    /// attach it to - mirrors the delay the old crash-report upload used, before that upload was
    /// replaced with MetricKit-correlation-only storage for real NSException/signal crashes.
    private var startupTask: Task<Void, Error>?

    init(
        crashReportPersistence: CrashReportPersisting.Type,
        logger: Logging,
        uploader: Uploading,
        session: @escaping SessionProvider,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.crashReportPersistence = crashReportPersistence
        self.logger = logger
        self.uploader = uploader
        self.session = session
        self.intervalProvider = intervalProvider

        if let crashReport = crashReportPersistence.read() {
            PendingCrashRecordStore.save(PendingCrashRecord(sessionID: crashReport.sessionID,
                                                             pageName: crashReport.pageName,
                                                             trafficSegment: crashReport.segment,
                                                             pageType: crashReport.pageType,
                                                             breadcrumbs: crashReport.report.nativeApp.breadcrumbs,
                                                             crashTime: nil),
                                         key: .pendingCrashRecord)
            crashReportPersistence.clear()
        }

        if let fatalReport = PendingCrashRecordStore.load(CrashReport.self, key: .pendingFatalErrorRecord) {
            self.startupTask = Task.delayed(byTimeInterval: Constants.startupDelay, priority: .utility) { [weak self] in
                defer { self?.startupTask = nil }
                self?.uploadFatalReport(fatalReport)
            }
        }
    }

    func stop(){
        self.startupTask?.cancel()
        self.startupTask = nil
        CrashReportPersistence.disableExaptionHandler()
        crashReportPersistence.clear()
    }

    private func uploadFatalReport(_ fatalReport: CrashReport) {
        // No session yet - leave the record in place for the next launch to retry rather than losing
        // it here.
        guard let session = session() else { return }
        var sessionCopy = session
        sessionCopy.sessionID = fatalReport.sessionID
        do {
            try upload(session: sessionCopy,
                      report: fatalReport.report,
                      pageName: fatalReport.pageName,
                      segment: fatalReport.segment ?? session.trafficSegmentName,
                      pageType: fatalReport.pageType ?? session.pageType,
                      event: BTTEvents.iOSCrash)
            PendingCrashRecordStore.remove(key: .pendingFatalErrorRecord)
        } catch {
            logger.error(error.localizedDescription)
        }
    }

    func logFatalError<E: Error>(
        _ error: E,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        let timer = BlueTriangle.recentTimer()
        let fatalErrorSignpost = SignpostLogger(category: "\(BlueTriangle.sessionID) + \(timer?.getPageName() ?? "Unknown")")
        fatalErrorSignpost.begin(name: Constants.externalFatalErrorSignpostName)
        fatalErrorSignpost.end(name: Constants.externalFatalErrorSignpostName)
        let crashReport = CrashReport(sessionID: BlueTriangle.sessionID,
                                      message: String(describing: error),
                                      pageName: timer?.getPageName(),
                                      segment: timer?.getTrafficSegment(),
                                      pageType: timer?.page.pageType,
                                      nativeApp: CrashReportPersistence.nativeAppProperties(),
                                      intervalProvider: intervalProvider())
        PendingCrashRecordStore.save(crashReport, key: .pendingFatalErrorRecord)
    }

    func uploadError<E: Error>(
        _ error: E,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        guard let session = session() else {
            return
        }
        
        do {
            if let timer = BlueTriangle.recentTimer() {
                let breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
                Task {
                    let message =  String(describing: error)
                    await errorMetricStore.addError(id: timer.uuid, message: message, line: line, breadcrumbs: breadcrumbs)
                }
            } else {
                var nativeApp = NativeAppProperties.nstEmpty
                nativeApp.breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
                let report = ErrorReport(nativeApp: nativeApp, eTp: BT_ErrorType.NativeAppCrash.rawValue, error: error, line: line, time: intervalProvider().milliseconds)
                let event = BTTEvents.iOSCrash
                try upload(session:session , report: report, pageName: event.defaultPageName, segment: session.trafficSegmentName, pageType: session.pageType, event: event)
            }

        } catch {
            logger.error(error.localizedDescription)
        }
    }
    
    func uploadErrorForPage(pageName: String, uuid: UUID, segment : String, pageType : String) {
        Task {
            do {
                guard let session = self.session(), let errorMetric = await self.errorMetricStore.flushError(id: uuid) else {
                    return
                }
                
                var nativeApp = NativeAppProperties.nstEmpty
                nativeApp.breadcrumbs = errorMetric.breadcrumbs
                let event = BTTEvents.iOSCrash
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMetric.message])
                let report = ErrorReport(nativeApp: nativeApp, eTp: BT_ErrorType.NativeAppCrash.rawValue, error: error , line: errorMetric.line, time: errorMetric.time.milliseconds, eCnt: errorMetric.eCount)
                let reportRequest = try makeErrorReportRequest(session: session,
                                                               report: report, pageName: pageName, segment: segment, pageType: pageType, event: event)
                uploader.send(request: reportRequest)
            } catch {
                self.logger.error(error.localizedDescription)
            }
        }
    }
}

// MARK: - Private
private extension CrashReportManager {
    func makeTimerRequest(session: Session, report: ErrorReport, pageName : String?, segment : String , pageType : String, event: BTTEvent) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageType = !pageType.isEmpty ? pageType :  session.pageType
        let page = Page(pageName: pageName ?? event.defaultPageName, pageType: pageType)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        var nativeProperty =  report.nativeApp.copy(.Regular)
        nativeProperty.breadcrumbs = nil
        if  pageName == nil { nativeProperty.eventId = event.id }
        let customMetrics = session.customVarriables(logger: logger)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 customMetrics: customMetrics,
                                 trafficSegmentName: trafficSegment,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 nativeAppProperties: nativeProperty,
                                 isErrorTimer: true)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }

    func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String?, segment : String, pageType : String, event: BTTEvent) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageType = !pageType.isEmpty ? pageType :  session.pageType
        
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? event.defaultPageName,
            "txnName": trafficSegment,
            "sessionID": String(session.sessionID),
            "pgTm": String(Constants.minPgTm),
            "pageType": pageType,
            "AB": session.abTestID,
            "DCTR": session.dataCenter,
            "CmpN": session.campaignName,
            "CmpM": session.campaignMedium,
            "CmpS": session.campaignSource,
            "os": Constants.os,
            "browser": Constants.browser,
            "browserVersion": Device.bvzn,
            "device": Constants.device
        ]

        return try Request(method: .post,
                           url: Constants.errorEndpoint,
                           parameters: params,
                           model: [report])
    }

    func upload(session: Session, report: ErrorReport, pageName : String?, segment : String, pageType : String, event: BTTEvent) throws {
        let timerRequest = try makeTimerRequest(session: session,
                                                report: report, pageName: pageName, segment : segment, pageType: pageType, event: event)
        uploader.send(request: timerRequest)

        let reportRequest = try makeErrorReportRequest(session: session,
                                                       report: report, pageName: pageName, segment : segment, pageType: pageType, event: event)
        uploader.send(request: reportRequest)
    }
}
