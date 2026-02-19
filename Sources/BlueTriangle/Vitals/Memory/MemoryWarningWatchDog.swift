//
//  MemoryWarningWatchDog.swift
//
//  Created by JP on 31/07/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

class MemoryWarningWatchDog {    
    let session: SessionProvider
    let uploader: Uploading
    let logger: Logging
    let errorMetricStore = ErrorMetricStore()
    
    init(session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging ) {
        
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
    }
    
    func start(){
        removeObserver()
        resisterObserver()
        logger.info("Memory Warning WatchDog started.")
    }
    
    func stop(){
        removeObserver()
    }
    
    @objc func raiseMemoryWarning(){
       
        guard let session = session() else {
            return
        }
        
        logger.debug("Memory Warning WatchDog :Memory Warning detected...  ")
        let message = formatedMemoryWarningMessage()

        if let timer = BlueTriangle.recentTimer() {
            Task {
                await self.errorMetricStore.addMemoryWarning(id: timer.uuid, message: message)
            }
        } else {
            let event = BTTEvents.memoryWarning
            let report = CrashReport(sessionID: BlueTriangle.sessionID,
                                     memoryWarningMessage: message, pageName: event.defaultPageName, segment: session.trafficSegmentName, pageType: session.pageType)
            uploadReports(session: session, report: report, segment: session.trafficSegmentName, pageType: session.pageType, event: event)
        }
        logger.debug(message)
    }
    
    private func formatedMemoryWarningMessage() -> String{
        let message = "Critical memory usage detected. iOS raised memory warning. App received UIApplication.didReceiveMemoryWarningNotification notification."
        return message
    }
    
   
    //MARK: - Memory Warning observers
    
    private func resisterObserver(){
#if os(iOS)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(raiseMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
#endif
    }
    
    private func removeObserver(){
#if os(iOS)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didReceiveMemoryWarningNotification,
                                                  object: nil)
#endif
    }
    
    deinit {
        removeObserver()
    }
}

extension MemoryWarningWatchDog {
   
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
    
    internal func uploadMemoryWarningReport(pageName: String, uuid: UUID, segment : String, pageType : String) {
        Task {
            do {
                guard let session = self.session(), let errorMetric = await self.errorMetricStore.flushMemoryWarning(id: uuid) else {
                    return
                }
                let event = BTTEvents.memoryWarning
                let report = CrashReport(sessionID: BlueTriangle.sessionID, memoryWarningMessage: errorMetric.message, eCount: errorMetric.eCount, pageName: pageName, segment: segment, pageType: pageType, intervalProvider: errorMetric.time)
                let reportRequest = try self.makeCrashReportRequest(session: session,
                                                                    report: report.report, pageName: report.pageName, segment: segment, pageType: pageType, event: event)
                self.uploader.send(request: reportRequest)
            } catch {
                self.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, report: ErrorReport, pageName: String?, segment : String, pageType : String, event: BTTEvent ) throws -> Request {
        let trafficSegment = !segment.isEmpty ? segment : session.trafficSegmentName
        let pageTypeValue = !pageType.isEmpty ? pageType :  session.pageType
        let page = Page(pageName: pageName ?? event.defaultPageName, pageType: pageTypeValue)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        var nativeProperty = BlueTriangle.recentTimer()?.nativeAppProperties ?? .empty
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
