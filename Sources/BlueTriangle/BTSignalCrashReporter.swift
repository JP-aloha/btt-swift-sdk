//
//  BTCrashReporter.swift
//
//
//  Created by Ashok Singh on 01/07/24.
//

import UIKit
#if canImport(AppEventLogger)
import AppEventLogger
#endif

struct SignalCrash: Codable {
    var signal: String
    var signo: Int
    var errno: Int
    var sig_code: Int
    var exit_value: Int
    var crash_time: UInt64
    var app_version: String
    var btt_session_id: String
    var btt_page_name: String?
}


class BTSignalCrashReporter {
    
    private let  directory : String
    
    private let logger: Logging
    
    private let uploader: Uploading
    
    private let sessionProvider: () -> Session
    
    private let intervalProvider: () -> TimeInterval
    
    private var startupTask: Task<Void, Error>?
    
    init(
        directory: String,
        logger: Logging,
        uploader: Uploading,
        sessionProvider: @escaping () -> Session,
        intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.directory = directory
        self.logger = logger
        self.uploader = uploader
        self.sessionProvider = sessionProvider
        self.intervalProvider = intervalProvider
    }
    
    func configureSignalCrashHandling(configuration: CrashReportConfiguration) {
        switch configuration {
        case .nsException:
            self.uploadAllStoredSignalCrashes()
        }
    }
    
    private func uploadAllStoredSignalCrashes(){
        do{
            let session = self.sessionProvider()
            let crashes = try self.getAllCrashes()
            for crash in crashes {
                uploadSignalCrash(crash, session)
            }
        }catch{
            logger.error("BlueTriangle:SignalCrashReporter: \(error.localizedDescription)")
        }
    }
    
    private func uploadSignalCrash(_ crash: SignalCrash, _ session: Session) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            do {
                guard let strongSelf = self else {
                    return
                }
                
                if let sessionId = UInt64(crash.btt_session_id){
                    var sessionCopy = session
                    sessionCopy.sessionID = sessionId
                    let pageName = (crash.btt_page_name ?? "").count > 0 ? crash.btt_page_name : Constants.crashID
                    let message = """
App crashed \(crash.signal)
signo : \(crash.signo)
errno : \(crash.errno)
signal code : \(crash.sig_code)
exit value : \(crash.exit_value)
"""
                    let exception = NSException(name: NSExceptionName("NSRangeException"), reason: message)
                    let crashReport = CrashReport(sessionID: sessionId, exception: exception, pageName: pageName, intervalProvider: TimeInterval(crash.crash_time))
                    try strongSelf.upload(session: sessionCopy, report: crashReport.report, pageName: crashReport.pageName)
                    try strongSelf.removeFile(crash)
                }
            }catch {
                self?.logger.error("BlueTriangle:SignalCrashReporter: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private
private extension BTSignalCrashReporter {
    private  func makeTimerRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let page = Page(pageName: pageName ?? Constants.crashID, pageType: Device.name)
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
    
    private  func makeErrorReportRequest(session: Session, report: ErrorReport, pageName : String?) throws -> Request {
        let params: [String: String] = [
            "siteID": session.siteID,
            "nStart": String(report.time),
            "pageName": pageName ?? Constants.crashID,
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
    
    private func upload(session: Session, report: ErrorReport, pageName : String?) throws {
        let timerRequest = try self.makeTimerRequest(session: session,
                                                     report: report, pageName: pageName)
        self.uploader.send(request: timerRequest)
        
        let reportRequest = try self.makeErrorReportRequest(session: session,
                                                            report: report, pageName: pageName)
        self.uploader.send(request: reportRequest)
    }
}

extension BTSignalCrashReporter{
    
    // Parse given file to SignalCrash
    private func readFile(_ fileName : String) throws -> SignalCrash?{
        let decoder = JSONDecoder()
        let url = URL(fileURLWithPath: self.directory)
        let file = File.init(directory: url, name: fileName)
        let persistence = Persistence.init(file: file)
        let data : Data
        print(file.url.absoluteString)
        
        if let fileData = try persistence.readData(){
            data = fileData
        }else{
            data = Data()
        }
        
        return try decoder.decode(SignalCrash.self, from: data)
    }
    
    // Get All SignalCrash form files
    private  func getAllCrashes() throws -> [SignalCrash]{
        
        var crashes = [SignalCrash]()
        let files = try self.getAllFiles()
        
        for file in files {
            guard let crashData = try self.readFile(file) else { return crashes}
            crashes.append(crashData)
        }
        
        return crashes
    }
    
    // Fetch All .bttcrash files from given directory
    private  func getAllFiles() throws -> [String]{
        
        var fileList = [String]()
        let directory = self.directory
        
        if let files = try? FileManager.default.contentsOfDirectory(atPath:directory).filter({ name in return name.contains(".bttcrash")}){
            fileList.append(contentsOf: files)
        }
        
        return fileList
    }
    
    private  func removeFile(_ crash : SignalCrash) throws{
        let url = URL(fileURLWithPath: self.directory)
        let file = File.init(directory: url, name: "\(crash.crash_time).bttcrash")
        let persistence = Persistence.init(file: file)
        try persistence.clear()
    }
}
