//
//  MemoryWarningWatchDog.swift
//
//  Created by Ashok Singh on 15/08/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

class MemoryWarningWatchDog {

    static let TIMER_PAGE_NAME = "MemoryWarning"
    
    let session: Session
    let uploader: Uploading
    let logger: Logging
    
    init(session: Session,
         uploader: Uploading,
         logger: Logging ) {
        
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
    }
    
    func start(){
        resisterObserver()
        logger.info("Memory Warning WatchDog started.")
    }
    
    @objc func raiseMemoryWarning(){
       
        logger.debug("Memory Warning WatchDog :Memory Warning detected...  ")
        
        let message = formatedMemoryWarning()
        let pageName = BlueTriangle.recentTimer()?.page.pageName
        let report = CrashReport(sessionID: BlueTriangle.sessionID,
                                 memoryWarningMessage: message, pageName: pageName)
        uploadReports(session: session, report: report)
        logger.debug(message)
    }
    
    private func formatedMemoryWarning() -> String{
        let memory =  ResourceUsage.memory() / 1024 / 1024
        let message = "Critical memory usage detected. iOS raised memory warning. App using \(memory) MB."
        return message
    }
    
   
    //MARK: - Memory Warning observers
    
    private func resisterObserver(){
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(raiseMemoryWarning),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
    }
    
    private func removeObserver(){
        NotificationCenter.default.removeObserver(self,
                                                          name: UIApplication.didReceiveMemoryWarningNotification,
                                                          object: nil)
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
        let page = Page(pageName: pageName ?? MemoryWarningWatchDog.TIMER_PAGE_NAME, pageType: Device.name)
        let timer = PageTimeInterval(startTime: report.time, interactiveTime: 0, pageTime: 15)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 purchaseConfirmation: nil,
                                 performanceReport: nil,
                                 excluded: Constants.excludedValue,
                                 isErrorTimer: true)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
        
    private func makeCrashReportRequest(session: Session, report: ErrorReport, pageName: String?) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? MemoryWarningWatchDog.TIMER_PAGE_NAME,
            "txnName": session.trafficSegmentName,
            "sessionID": String(session.sessionID),
            "pgTm": "0",
            "pageType": Device.name,
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
