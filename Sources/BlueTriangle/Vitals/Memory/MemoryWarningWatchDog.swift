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

    static let DEFAULT_PAGE_NAME = BT_ErrorType.MemoryWarning.rawValue
    
    let session: SessionProvider
    let uploader: Uploading
    let logger: Logging
    
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
        let pageName = BlueTriangle.recentTimer()?.page.pageName
        let report = CrashReport(sessionID: BlueTriangle.sessionID,
                                 memoryWarningMessage: message, pageName: pageName)
        uploadReports(session: session, report: report)
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
   
    private func uploadReports(session: Session, report: CrashReport) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }
                
                let timerRequest = try strongSelf.makeTimerRequest(session: session,
                                                                   report: report.report, pageName: report.pageName)
                 strongSelf.uploader.send(request: timerRequest)
                
                let reportRequest = try strongSelf.makeCrashReportRequest(session: session,
                                                                          report: report.report, pageName: report.pageName)
                strongSelf.uploader.send(request: reportRequest)
            } catch {
                self?.logger.error(error.localizedDescription)
            }
        }
    }
    
    private func makeTimerRequest(session: Session, report: ErrorReport, pageName: String?) throws -> Request {
        let page = Page(pageName: pageName ?? MemoryWarningWatchDog.DEFAULT_PAGE_NAME, pageType: "")
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: Constants.minPgTm)
        let nativeProperty = BlueTriangle.recentTimer()?.nativeAppProperties ?? .empty
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
        
    private func makeCrashReportRequest(session: Session, report: ErrorReport, pageName: String?) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? MemoryWarningWatchDog.DEFAULT_PAGE_NAME,
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
    
}
