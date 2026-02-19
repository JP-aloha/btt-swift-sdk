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
        self.startupTask = Task.delayed(byTimeInterval: Constants.startupDelay, priority: .utility) { [weak self] in
            guard let session = self?.session() else {
                return
            }

            self?.uploadCrashReport(session: session)
            self?.startupTask = nil
        }
    }
    
    func stop(){
        //Clear saved crash
        self.startupTask?.cancel()
        self.startupTask = nil
        CrashReportPersistence.disableExaptionHandler()
        crashReportPersistence.clear()
    }

    func uploadCrashReport(session: Session) {
        guard let crashReport = crashReportPersistence.read() else {
            return
        }

        // Update session to use values from when the app crashed
        var sessionCopy = session
        sessionCopy.sessionID = crashReport.sessionID

        do {
            let event = BTTEvents.iOSCrash
            try upload(session: sessionCopy, report: crashReport.report, pageName: crashReport.pageName, segment: crashReport.segment ?? session.trafficSegmentName, pageType: crashReport.pageType ?? session.pageType, event: event)

            crashReportPersistence.clear()
        } catch {
            logger.error(error.localizedDescription)
        }
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
                Task {
                    let message =  String(describing: error)
                    await errorMetricStore.addError(id: timer.uuid, message: message, line: line)
                }
            } else {
                let nativeApp = NativeAppProperties.nstEmpty
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
                
                let nativeApp = NativeAppProperties.nstEmpty
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
