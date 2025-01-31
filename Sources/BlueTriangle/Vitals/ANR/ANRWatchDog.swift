//
//  ANRWatchDog.swift
//  TimerRequest
//
//  Created by JP on 22/04/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

class ANRWatchDog{
    static let DEFAULT_ERROR_INTERVAL_SEC: TimeInterval = 5
    static let MIN_ERROR_INTERVAL_SEC: TimeInterval = 3
    static let MAX_ERROR_INTERVAL_SEC: TimeInterval = 100
    static let TIMER_PAGE_NAME = "ANRWarning"
  
    private var _errorTriggerInterval = ANRWatchDog.DEFAULT_ERROR_INTERVAL_SEC
    var enableStackTrace: Bool = false

    var errorTriggerInterval: TimeInterval {
        
        get{
            return _errorTriggerInterval
        }
        
        set{
            if newValue >= ANRWatchDog.MIN_ERROR_INTERVAL_SEC && newValue <= ANRWatchDog.MAX_ERROR_INTERVAL_SEC{
                _errorTriggerInterval = errorTriggerInterval
            }else{
                logger.error("ANR Watch Dog: Skipping error interval value \(newValue). not in allowed range \(ANRWatchDog.MIN_ERROR_INTERVAL_SEC) to \(ANRWatchDog.MAX_ERROR_INTERVAL_SEC) Sec.")
            }
        }
    }
    
    let sampleTimeInterval: TimeInterval    = 2
    let mainThreadObserver: MainThreadObserver
    let session: SessionProvider
    let uploader: Uploading
    let logger: Logging
    
    init(mainThreadObserver: MainThreadObserver,
         session: @escaping SessionProvider,
         uploader: Uploading,
         logger: Logging ) {
        
        self.mainThreadObserver = mainThreadObserver
        self.logger     = logger
        self.uploader   = uploader
        self.session    = session
        
        MainThreadTraceProvider.shared.setup()
    }
    
    func start(){
        self.mainThreadObserver.start()
        startObservationTimer()
        let anrInfoMessage = "ANR Watch Dog started. Main thread will be checked for every \(self.sampleTimeInterval) Sec. If a task is running longer then \(self.errorTriggerInterval) ANRWarning will be raised."
        logger.info(anrInfoMessage)
    }
    
   func stop(){
        self.mainThreadObserver.stop()
        stopObservationTimer()
       logger.info("ANR Watch Dog Stopped.")
    }
    
    private var bgTimer : DispatchSourceTimer?
    private let timerDispatchQueue = DispatchQueue(label: "com.BTT.ANRWatchDogTimer")

    private func startObservationTimer(){
        stopObservationTimer()
        bgTimer = DispatchSource.makeTimerSource(queue: timerDispatchQueue)
        bgTimer?.schedule(deadline: DispatchTime.now(),
                          repeating: DispatchTimeInterval.seconds(1),
                          leeway: DispatchTimeInterval.never)
        bgTimer?.setEventHandler(handler: checkRunningTaskDuration)
        bgTimer?.resume()
    }
    
    private var lastRaisedTask : ThreadTask?
    private func checkRunningTaskDuration(){
        
        if let task = mainThreadObserver.runningTask, task.duration() > errorTriggerInterval{
            if lastRaisedTask === task{
                logger.debug("ANR Watch Dog Checking : Already raised task found skip ")
                return //raise error only once for a task
            }
            
            raiseANRError()
            lastRaisedTask = task
        }
    }

    private func stopObservationTimer(){
        if let timer = bgTimer{
            timer.cancel()
            bgTimer = nil
            logger.debug("ANR Watch Dog Stopped timer... ")
        }
    }
    
    private func raiseANRError(){
        
        guard let session = session() else {
            return
        }
        
        logger.debug("ANR Watch Dog : Warning potential ANR detected...  ")
        
        let message = """
Potential ANR Detected
An task blocking main thread since \(self.errorTriggerInterval) seconds
"""
        let pageName = BlueTriangle.recentTimer()?.page.pageName
        let report = CrashReport(sessionID: BlueTriangle.sessionID, ANRmessage: message, pageName: pageName)
        uploadReports(session: session, report: report)
        logger.debug(message)
    }
    
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
        let page = Page(pageName: pageName ?? ANRWatchDog.TIMER_PAGE_NAME, pageType: "")
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
            "pageName": pageName ?? ANRWatchDog.TIMER_PAGE_NAME,
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
