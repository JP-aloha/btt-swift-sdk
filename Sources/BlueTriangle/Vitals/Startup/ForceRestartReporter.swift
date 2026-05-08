//
//  ForceKillReporter.swift
//  blue-triangle
//
//  Created by Ashok Singh on 06/05/26.
//

import Foundation

class ForceRestartReporter {
    private let session: SessionProvider
    private let uploader: Uploading
    private let logger: Logging
    
    init(using session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging) {
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
    }
    
    func reportForceRestartForPage(_ activity : ActivityRecord){
        logger.debug("BlueTriangle:ForceRestartReporter -Force Restart detected...  ")
        let message = "User force restarted app."
        self.uploadMemoryWarningReport(message: message, pageName: activity.pageName, segment: activity.trafficSegment, pageType: activity.pageType)
        logger.debug(message)
    }
}

extension ForceRestartReporter {
   
    internal func uploadMemoryWarningReport(message : String, pageName: String, segment : String, pageType : String) {
        Task {
            do {
                guard let session = self.session() else { return }
                let event = BTTEvents.forceRestart
                var nativeApp = NativeAppProperties.nstEmpty
                nativeApp.breadcrumbs = BlueTriangle.breadcrumbManager?.breadcrumbs()
                let report = CrashReport(sessionID: BlueTriangle.sessionID, forceRestartMessage: message, eCount: 1, pageName: pageName, segment: segment, pageType: pageType, nativeApp: nativeApp)
                let reportRequest = try self.makeForceRestartReportRequest(session: session,
                                                                    report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                self.uploader.send(request: reportRequest)
            } catch {
                self.logger.error(error.localizedDescription)
            }
        }
    }
        
    private func makeForceRestartReportRequest(session: Session, report: ErrorReport, pageName: String?, segment : String, pageType : String, event: BTTEvent) throws -> Request {
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
