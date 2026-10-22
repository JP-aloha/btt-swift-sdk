//
//  NetworkErrorWatchDog.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

class NetworkErrorWatchDog {
    let session: SessionProvider
    let uploader: Uploading
    let logger: Logging
    let errorMetricStore = ErrorMetricStore()

    init(session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging) {
        self.logger   = logger
        self.uploader = uploader
        self.session  = session
    }

    func raiseNetworkError(method: String?, url: String, error: Error) {
        guard let session = session() else {
            return
        }

        let message = formattedMessage(method: method, url: url, error: error)
        logger.debug("Network Error WatchDog: \(message)")

        if let timer = BlueTriangle.recentTimer() {
            timer.setEvent(BTTEvents.networkError)
            let breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
            Task {
                await self.errorMetricStore.addNetworkError(id: timer.uuid, url: url, message: message, breadcrumbs: breadcrumbs)
            }
        } else {
            let event = BTTEvents.networkError
            var nativeApp = NativeAppProperties.nstEmpty
            nativeApp.breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
            nativeApp.eMeta = EMetaBuilder.build(source: .networkError, build: EMetaBuilder.currentBuild, arch: EMetaBuilder.currentArch)
            let report = CrashReport(sessionID: BlueTriangle.sessionID,
                                     networkErrorMessage: message, pageName: event.defaultPageName, segment: session.trafficSegmentName, pageType: session.pageType, nativeApp: nativeApp)
            uploadReports(session: session, report: report, segment: session.trafficSegmentName, pageType: session.pageType, event: event)
        }
    }

    /// e.g. "GET https://untrusted-root.badssl.com/ failed with URLError : The certificate for this
    /// server is invalid."
    private func formattedMessage(method: String?, url: String, error: Error) -> String {
        let httpMethod = method.map { "\($0.uppercased()) " } ?? ""
        let exceptionName = String(describing: type(of: error))
        return "\(httpMethod)\(url) failed with \(exceptionName) : \(error.localizedDescription)"
    }
}

extension NetworkErrorWatchDog {

    private func uploadReports(session: Session, report: CrashReport, segment : String, pageType: String, event: BTTEvent) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }

                let timerRequest = try strongSelf.makeTimerRequest(session: session,
                                                                   report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                strongSelf.uploader.send(request: timerRequest)

                let reportRequest = try strongSelf.makeCrashReportRequest(session: session,
                                                                          report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                strongSelf.uploader.send(request: reportRequest)
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }


    internal func uploadNetworkErrorReport(pageName: String, uuid: UUID, segment : String, pageType : String) {
        Task {
            guard let session = self.session(), let urlErrors = await self.errorMetricStore.flushNetworkErrors(id: uuid) else {
                return
            }
            let event = BTTEvents.networkError
            for (_, errorMetric) in urlErrors {
                do {
                    var nativeApp = NativeAppProperties.nstEmpty
                    nativeApp.breadcrumbs = errorMetric.breadcrumbs
                    nativeApp.eMeta = EMetaBuilder.build(source: .networkError, build: EMetaBuilder.currentBuild, arch: EMetaBuilder.currentArch)
                    let report = CrashReport(sessionID: BlueTriangle.sessionID, networkErrorMessage: errorMetric.message, eCount: errorMetric.eCount, pageName: pageName, segment: segment, pageType: pageType, nativeApp: nativeApp, intervalProvider: errorMetric.time)
                    let reportRequest = try self.makeCrashReportRequest(session: session,
                                                                        report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                    self.uploader.send(request: reportRequest)
                } catch {
                    self.logger.error(error.localizedDescription)
                }
            }
        }
    }

    private func makeTimerRequest(session: Session, report: ErrorReport, pageName: String?, segment : String, pageType : String, event: BTTEvent) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageTypeValue = !pageType.isEmpty ? pageType :  session.pageType
        let page = Page(pageName: pageName ?? event.defaultPageName, pageType: pageTypeValue)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        var nativeProperty = BlueTriangle.recentTimer()?.nativeAppProperties ?? .empty
        nativeProperty.eventId = event.id
        nativeProperty.breadcrumbs = nil
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

    private func makeCrashReportRequest(session: Session, report: ErrorReport, pageName: String?, segment : String, pageType : String, event: BTTEvent) throws -> Request {
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
}
