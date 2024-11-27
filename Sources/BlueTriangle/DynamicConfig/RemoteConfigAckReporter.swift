//
//  RemoteConfigAckReporter.swift
//  
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import UIKit

class RemoteConfigAckReporter {

    private let queue = DispatchQueue(label: "com.bluetriangle.ack.reporter", qos: .userInitiated, autoreleaseFrequency: .workItem)
    
    private let logger: Logging
    
    private let uploader: Uploading
    
    init(logger: Logging, uploader: Uploading) {
        self.logger = logger
        self.uploader = uploader
    }
    
    func reportSuccessAck(){
        queue.async {
            do {
                let session = BlueTriangle.session()
                let pageName = "BTTConfigUpdate"
                try self.upload(session: session,
                                pageName: pageName)
            }catch {
                self.logger.error("BlueTriangle:RemoteConfigAckReporter: \(error.localizedDescription)")
            }
        }
    }
    
    func reportFailAck(_ error : Error){
        queue.async {
            do {
                    let session = BlueTriangle.session()
                    let pageName = "BTTConfigUpdate"
                    let message = error.localizedDescription
                   let crashReport = CrashReport(errorType : BT_ErrorType.BTTConfigUpdateError, sessionID: session.sessionID, message: message, pageName: pageName)
                   try self.upload(session: session,
                                   report: crashReport.report,
                                   pageName: pageName)
        
            }catch {
                self.logger.error("BlueTriangle:RemoteConfigAckReporter: \(error.localizedDescription)")
            }
        }
    }
}

private extension RemoteConfigAckReporter {
    func makeTimerRequest(session: Session, report: ErrorReport, pageName : String) throws -> Request {
        let page = Page(pageName: pageName)
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
    
    func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName,
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
    
    func upload(session: Session, report: ErrorReport, pageName : String) throws {
        let timerRequest = try makeTimerRequest(session: session,
                                                report: report, pageName: pageName)
        uploader.send(request: timerRequest)
        
        let reportRequest = try makeErrorReportRequest(session: session,
                                                       report: report, pageName: pageName)
        uploader.send(request: reportRequest)
    }
}

private extension RemoteConfigAckReporter {
    
    func upload(session: Session, pageName : String) throws {
        
        let timeMS = Date().timeIntervalSince1970.milliseconds
        let durationMS = Constants.minPgTm
        let timerRequest = try self.makeTimerRequest(session: session,
                                                           time: timeMS,
                                                           duration: durationMS,
                                                     pageName: pageName)
        self.uploader.send(request: timerRequest)
    }
    
    private func makeTimerRequest(session: Session, time : Millisecond, duration : Millisecond , pageName: String) throws -> Request {
        let page = Page(pageName: pageName)
        let timer = PageTimeInterval(startTime: time, interactiveTime: 0, pageTime: duration)
        let model = TimerRequest(session: session,
                                 page: page,
                                 timer: timer,
                                 nativeAppProperties: .nstEmpty)
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           model: model)
    }
}
