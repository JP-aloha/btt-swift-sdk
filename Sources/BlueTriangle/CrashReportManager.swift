//
//  CrashReportManager.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

final class CrashReportManager: CrashReportManaging {

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
            try upload(session: sessionCopy, report: crashReport.report, pageName: crashReport.pageName)

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
        
        let nativeApp = NativeAppProperties.nstEmpty
        let report = ErrorReport(nativeApp: nativeApp, eTp: BT_ErrorType.NativeAppCrash.rawValue, error: error, line: line, time: intervalProvider().milliseconds)
        let pageName = BlueTriangle.recentTimer()?.page.pageName
        do {
            try upload(session:session , report: report, pageName: pageName)
        } catch {
            logger.error(error.localizedDescription)
        }
    }
}

// MARK: - Private
private extension CrashReportManager {
    func makeTimerRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let page = Page(pageName: pageName ?? Constants.crashID, pageType: "")
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        let nativeProperty =  report.nativeApp.copy(.Regular)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 nativeAppProperties: nativeProperty,
                                 isErrorTimer: true)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }

    func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? Constants.crashID,
            "txnName": session.trafficSegmentName,
            "sessionID": String(session.sessionID),
            "pgTm": "0",
            "pageType": "",
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

    func upload(session: Session, report: ErrorReport, pageName : String?) throws {
        let timerRequest = try makeTimerRequest(session: session,
                                                report: report, pageName: pageName)
        uploader.send(request: timerRequest)

        let reportRequest = try makeErrorReportRequest(session: session,
                                                       report: report, pageName: pageName)
        uploader.send(request: reportRequest)
    }
    
}
