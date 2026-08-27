//
//  MetricKitWatchDog+Upload.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
import Foundation

extension MetricKitWatchDog {
    func uploadReports(session: Session, report: CrashReport, segment: String, pageType: String, event: BTTEvent) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                let timerRequest = try strongSelf.makeTimerRequest(session: session,
                                                                   report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                strongSelf.uploader.send(request: timerRequest)

                let reportRequest = try strongSelf.makeCrashReportRequest(session: session,
                                                                          report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                strongSelf.uploader.send(request: reportRequest)

                strongSelf.logger.debug("MetricKit Watch Dog: submitted timer + error-report beacons for \(event.defaultPageName) (sessionID: \(session.sessionID)).")
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }

    func uploadReportOnly(session: Session, report: CrashReport, pageName: String, segment: String, pageType: String, event: BTTEvent) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                let reportRequest = try strongSelf.makeCrashReportRequest(session: session, report: report.report, pageName: pageName, segment: segment, pageType: pageType, event: event)
                strongSelf.uploader.send(request: reportRequest)
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }

    /// Builds a `CrashReport` for `kind` and uploads it via `uploadReports` - shared by the crash path
    /// (`reportCrash()`) and the legacy no-current-page diagnostic path (`reportOrDefer()`).
    /// `pageName`/`trafficSegment`/`pageType` fall back to the current session's when not supplied.
    func uploadCrashReport(
        kind: MetricKitDiagnosticKind,
        sessionID: Identifier,
        message: String,
        pageName: String?,
        trafficSegment: String?,
        pageType: String?,
        breadcrumbs: String?,
        eMetadata: String? = nil,
        eIdentifier: String? = nil,
        session: Session,
        timeStampBegin: Date
    ) {
        var nativeApp = NativeAppProperties.nstEmpty
        nativeApp.breadcrumbs = breadcrumbs
        nativeApp.eMetadata = eMetadata
        nativeApp.eIdentifier = eIdentifier
        let event = kind.event
        let resolvedPageName = pageName ?? event.defaultPageName
        let resolvedTrafficSegment = trafficSegment ?? session.trafficSegmentName
        let resolvedPageType = pageType ?? session.pageType
        let crashReport = CrashReport(errorType: kind.errorType,
                                      sessionID: sessionID,
                                      message: message,
                                      pageName: resolvedPageName,
                                      segment: resolvedTrafficSegment,
                                      pageType: resolvedPageType,
                                      nativeApp: nativeApp,
                                      intervalProvider: timeStampBegin.timeIntervalSince1970)
        var sessionCopy = session
        sessionCopy.sessionID = sessionID

        uploadReports(session: sessionCopy, report: crashReport, segment: resolvedTrafficSegment, pageType: resolvedPageType, event: event)
    }

    func makeTimerRequest(session: Session, report: ErrorReport, pageName: String?, segment: String, pageType: String, event: BTTEvent) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageTypeValue = !pageType.isEmpty ? pageType : session.pageType
        let page = Page(pageName: pageName ?? event.defaultPageName, pageType: pageTypeValue)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        var nativeProperty = NativeAppProperties.empty
        nativeProperty.eventId = event.id
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

    func makeCrashReportRequest(session: Session, report: ErrorReport, pageName: String?, segment: String, pageType: String, event: BTTEvent) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageTypeValue = !pageType.isEmpty ? pageType : session.pageType
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? event.defaultPageName,
            "txnName": trafficSegment,
            "sessionID": String(session.sessionID),
            "pgTm": String(Constants.minPgTm),
            "pageType": pageTypeValue,
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
}
#endif
