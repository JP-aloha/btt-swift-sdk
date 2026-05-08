//
//  CrashReport.swift
//
//  Created by Mathew Gacy on 10/31/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct CrashReport: Codable {
    let sessionID: Identifier
    let pageName: String?
    let report: ErrorReport
    let segment: String?
    let pageType: String?
}

//Cunstructor to cunstruct Crash Report
extension CrashReport {
    
    // For NS Exception
    init(
        sessionID: Identifier,
        exception: NSException,
        pageName:String?,
        segment:String?,
        pageType:String?,
        nativeApp : NativeAppProperties = .nstEmpty,
        intervalProvider: TimeInterval =  Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName =  pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: 1,
                                  nativeApp: nativeApp,
                                  eTp: BT_ErrorType.NativeAppCrash.rawValue, message: exception.bttCrashReportMessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
    
    // For message
    init(
        sessionID: Identifier,
        message: String,
        pageName:String?,
        segment:String?,
        pageType:String?,
        nativeApp : NativeAppProperties = .nstEmpty,
        intervalProvider: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName =  pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: 1, nativeApp: nativeApp,
                                  eTp: BT_ErrorType.NativeAppCrash.rawValue, message: message.bttReportMessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
    
    // For message
    init(
        errorType : BT_ErrorType,
        sessionID: Identifier,
        message: String,
        pageName:String?,
        segment:String?,
        pageType:String?,
        intervalProvider: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName =  pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: 1,
                                  eTp: errorType.rawValue, message: message.bttReportMessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
}

//ANR Warning
extension CrashReport {
    init(
        sessionID: Identifier,
        ANRmessage: String,
        eCount: Int = 1,
        pageName:String?,
        segment:String?,
        pageType:String?,
        nativeApp : NativeAppProperties = .nstEmpty,
        intervalProvider: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName = pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: eCount,
                                  nativeApp: nativeApp,
                                  eTp: BT_ErrorType.ANRWarning.rawValue, message: ANRmessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
}

//MemoryWarning
extension CrashReport {
    init(
        sessionID: Identifier,
        memoryWarningMessage: String,
        eCount: Int = 1,
        pageName:String?,
        segment:String?,
        pageType:String?,
        nativeApp : NativeAppProperties = .nstEmpty,
        intervalProvider: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName = pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: eCount,
                                  nativeApp: nativeApp,
                                  eTp: BT_ErrorType.MemoryWarning.rawValue,
                                  message: memoryWarningMessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
}

//ForceRestart
extension CrashReport {
    init(
        sessionID: Identifier,
        forceRestartMessage: String,
        eCount: Int = 1,
        pageName:String?,
        segment:String?,
        pageType:String?,
        nativeApp : NativeAppProperties = .nstEmpty,
        intervalProvider: TimeInterval = Date().timeIntervalSince1970
    ) {
        self.sessionID = sessionID
        self.pageName = pageName
        self.segment = segment
        self.pageType = pageType
        self.report = ErrorReport(eCnt: eCount,
                                  nativeApp: nativeApp,
                                  eTp: BT_ErrorType.ForceRestart.rawValue,
                                  message: forceRestartMessage,
                                  line: 1,
                                  column: 1,
                                  time: intervalProvider.milliseconds)
    }
}

enum BT_ErrorType : String{
    case NativeAppCrash
    case ANRWarning
    case MemoryWarning
    case ForceRestart
}
