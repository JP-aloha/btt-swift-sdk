//
//  DignosticWatchDog.swift
//  Matric Dignostic
//
//  Created by jaiprakash bokhare on 28/06/23.
//

import Foundation
import MetricKit
import UIKit

class ErrorReporter: ObservableObject {
    
    struct ErrorReport: Identifiable {
        
        enum ErrorType: String {
            case Hang
            case Crash
            case Log
        }
        
        let id = UUID()
        let type: ErrorType
        let title: String
        let trace: String
    }
    
    init() {
        self.report(title: "#\(type(of: self)) \(#function) \(#line)", stack: "", errorType: .Log)
    }
    
    deinit {
        self.report(title: "#\(type(of: self)) \(#function) \(#line)", stack: "", errorType: .Log)
    }
    
    @Published private(set) var reports: [ErrorReport] = []
    
    func report(title: String, stack: String, errorType: ErrorReport.ErrorType){
        
        reports.append(ErrorReport(type: errorType, title: title, trace: stack))
        NSLog("#\(#function) \(title)\n  \(stack)")
    }
}

class HangWatchDog{
    
    private(set) var subscription = HangErrorSubscription(reporter: ErrorReporter())
    
    func start(){
        
        if #available(iOS 14.0, *) {
            let pastDiagnosticPayloads = MXMetricManager.shared.pastDiagnosticPayloads
            
            NSLog("#\(#function) Previous reports \(pastDiagnosticPayloads)")
            subscription.setupDignoseDataInReporter(payloads: pastDiagnosticPayloads)
        }
        
        MXMetricManager.shared.add(subscription)
        addAppStateObservers()
    }
    
    deinit {
        subscription.reporter.report(title: "#\(type(of: self)) \(#function) \(#line)", stack: "", errorType: .Log)
    }
    
    private func addAppStateObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func applicationResignActive() {
        
        UserDefaultsUtility.removeData(key: .currentPage)
        UserDefaultsUtility.removeData(key: .startTime)
        UserDefaultsUtility.removeData(key: .sessionId)
        
    }
    
    func saveCurrentTimerData(_ timer: BTTimer) {
        UserDefaultsUtility.setData(value: timer.page.pageName, key: .currentPage)
        UserDefaultsUtility.setData(value: Date().timeIntervalSince1970, key: .startTime)
        UserDefaultsUtility.setData(value: BlueTriangle.sessionID, key: .sessionId)
    }
}

class HangErrorSubscription : NSObject, MXMetricManagerSubscriber {
    
    let reporter: ErrorReporter
    private var formattedCrashReportString = ""
    
    init(reporter: ErrorReporter) {
        
        self.reporter = reporter
        NSLog("#\(#function)")
    }
    
}

// MARK: - MXMetricManagerSubscriber Delegates
extension HangErrorSubscription {
    
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Process metrics.l
        NSLog("# Received norma payload report \(#function)")
        
    }
    
    @available(iOS 14.0, *)
    func didReceive(_ payloads: [MXDiagnosticPayload]){
        
        NSLog("#Received Diagnostic report \(payloads)")
        
        setupDignoseDataInReporter(payloads: payloads)
        
    }
}

// MARK: - Setup recieved payload
extension HangErrorSubscription {
    
    @available(iOS 14.0, *)
    func setupDignoseDataInReporter(payloads: [MXDiagnosticPayload]) {
        
        reporter.report(title: "#\(type(of: self)) \(#function) \(#line)",
                        stack: "",
                        errorType: .Log)
        
        for report in payloads {
            
            for hangReport in report.hangDiagnostics ?? []{
                
                let title = "App Hand for \(hangReport.hangDuration.converted(to: .seconds)) Sec."
                let trace = String(data: hangReport.callStackTree.jsonRepresentation(), encoding: .utf8)
                
                reporter.report(title: title, stack: trace ?? "Error converting trace to string.", errorType: .Hang)
            }
            
            for crashReport in report.crashDiagnostics ?? []{
                
                let title = "App crashed because of:-  \(crashReport.terminationReason ?? "" ) \\ \(crashReport.exceptionCode ?? -1) \\ \(crashReport.exceptionType ?? -1)"
                let trace = String(data: crashReport.callStackTree.jsonRepresentation(), encoding: .utf8)
                
                reporter.report(title: title,
                                stack: trace ?? "Error converting trace to string.",
                                errorType: .Crash)
                
                createCrashReportModel(from: crashReport.jsonRepresentation(),
                                       terminationReason: crashReport.terminationReason ?? "Null",
                                       virtualMemoryRegionInfo: crashReport.virtualMemoryRegionInfo ?? "Null")
            }
        }
    }
    
}

// MARK: - Crate Crash Models
extension HangErrorSubscription {
    
   private func createCrashReportModel(from data: Data,
                                terminationReason: String,
                                virtualMemoryRegionInfo: String) {
        NSLog(#function)
        if let crashDataModel = decodeJsonResponse(data: data,
                                                   responseType: MetricKitCrashReport.self) {
            
            saveRportToPresistence(report: crashDataModel,
                                   terminationReason: terminationReason,
                                   virtualMemoryRegionInfo: virtualMemoryRegionInfo)
            
            NSLog("#Save crash data in Presistence ")
            
        }
    }
}

// MARK: Crate and Save formatted report to presistance
extension HangErrorSubscription {
    
    private  func saveRportToPresistence(report: MetricKitCrashReport,
                                terminationReason: String,
                                virtualMemoryRegionInfo: String) {
        
        var metaDataString = ""
        
        let pageName = UserDefaultsUtility.getData(type: String.self, forKey: .currentPage)
        let sessionId = UserDefaultsUtility.getData(type: Identifier.self, forKey: .sessionId) ?? BlueTriangle.sessionID
        let startTime = UserDefaultsUtility.getData(type: Double.self, forKey: .startTime) ?? 0.0
        let crashTime = "\n CrashTime: \(getFormattedDateString(timeInterval: startTime))"
        let reportTime = "\n ReportTime: \(getFormattedDateString(timeInterval: Date().timeIntervalSince1970))"
        
        metaDataString = metaDataString + crashTime + reportTime
        metaDataString = metaDataString + "\n " + getFormattedMetaData(metaData: report.diagnosticMetaData)
        metaDataString = metaDataString + "\n " + "TerminationReason: \(terminationReason)"
        metaDataString = metaDataString + "\n " + "VMReason: \(virtualMemoryRegionInfo)"
        metaDataString = metaDataString + "\n \n Traces"
        
        formattedCrashReportString += metaDataString
        getForamttedStringOfCallStacks(report: report)
        
        print(formattedCrashReportString)
        
        let crashReport  = CrashReport(sessionID: sessionId,
                                       message: formattedCrashReportString,
                                       pageName: pageName, intervalProvider: startTime)
        
      //  CrashReportPersistence.saveCrash(crashReport: crashReport)
    }
    
    private func getForamttedStringOfCallStacks(report: MetricKitCrashReport) {
        
        let callStacks = report.callStackTree.callStacks
        
        for (callStack, threadNumber) in  zip(callStacks, 0..<callStacks.count) {
            
            let crashedText = callStack.threadAttributed ? "Crashed" : ""
            let threadDetail = "\n \n Thread \(threadNumber) \(crashedText)"
            
            formattedCrashReportString = formattedCrashReportString + threadDetail
            
            for callStackRoodFrame in callStack.callStackRootFrames {
                
                setupDataFromSubframes(subFrames: callStackRoodFrame)
            }
        }
    }
    
    private func setupDataFromSubframes(subFrames: CallStackRootFrame)  {
        
        if !(subFrames.subFrames?.isEmpty ?? true) {
            
            for subFrame in subFrames.subFrames ?? [] {
                
                setupDataFromSubframes(subFrames: subFrame)
            }
        }
        
        let binaryName = decorateWithPadding(string: subFrames.binaryName, columnSize: 40)
        let binaryUUID = decorateWithPadding(string: subFrames.binaryUUID, columnSize: 40)
        let address = decorateWithPadding(string: "\(subFrames.address)", columnSize: 25)
        let offsetIntoBinaryTextSegment = decorateWithPadding(string: "+ \(subFrames.offsetIntoBinaryTextSegment)", columnSize: 20)
        let string = "\n \(binaryName) \(binaryUUID) \(address) \(offsetIntoBinaryTextSegment)"
        
        formattedCrashReportString += string
    }
    
    private func getFormattedMetaData(metaData: DiagnosticMetaData) -> String {
        
        var metaDataString = ""
        
        let applicationBuildVersion = "ApplicationBuildVersion: \(metaData.appBuildVersion)"
        metaDataString = metaDataString + applicationBuildVersion
        
        let deviceType = "DeviceType: \(metaData.deviceType)"
        metaDataString = metaDataString + "\n " + deviceType
        
        var isTestFlightAppString = ""
        
        if let isTestFlightApp = metaData.isTestFlightApp {
            
            isTestFlightAppString = "isTestFlightApp: \(isTestFlightApp ? "true" : "false")"
        }
        else {
            
            isTestFlightAppString = "isTestFlightApp: Null"
        }
        metaDataString = metaDataString + "\n " + isTestFlightAppString
        
        var lowPowerModeEnabledString = ""
        
        if let lowPowerModeEnabled = metaData.lowPowerModeEnabled {
            
            lowPowerModeEnabledString = "lowPowerModeEnabled: \(lowPowerModeEnabled ? "true" : "false")"
        }
        else {
            lowPowerModeEnabledString = "lowPowerModeEnabled: Null"
        }
        
        metaDataString = metaDataString + "\n " + lowPowerModeEnabledString
        
        let osVersion = "osVersion: \(metaData.osVersion)"
        metaDataString = metaDataString + "\n " + osVersion
        
        let platformArchitecture = "platformArchitecture: \(metaData.platformArchitecture)"
        metaDataString = metaDataString + "\n " + platformArchitecture
        
        let regionFormat = "regionFormat: \(metaData.regionFormat)"
        metaDataString = metaDataString + "\n " + regionFormat
        
        let exceptionType = "ExceptionType: \(metaData.exceptionType)"
        metaDataString = metaDataString + "\n " + exceptionType
        
        let exceptionCode = "ExceptionCode: \(metaData.exceptionCode)"
        metaDataString = metaDataString + "\n " + exceptionCode
        
        let signal = "Signal: \(CrashSignal.getSignalNumbeDetail(signal: metaData.signal))"
        metaDataString = metaDataString + "\n " + signal
        
        return metaDataString
    }
    
}

// MARK: Helper Methods
extension HangErrorSubscription {
    
   private func decodeJsonResponse<T: Decodable>(data: Data, responseType: T.Type) -> T? {
        
        let decoder =  JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(responseType, from: data)
        } catch let DecodingError.dataCorrupted(context) {
            debugPrint(context)
        } catch let DecodingError.keyNotFound(key, context) {
            debugPrint("Key '\(key)' not found:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            debugPrint("Value '\(value)' not found:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context) {
            debugPrint("Type '\(type)' mismatch:", context.debugDescription)
            debugPrint("codingPath:", context.codingPath)
        } catch {
            debugPrint("error: ", error)
        }
        return nil
    }
    
   private func getFormattedDateString(timeInterval: TimeInterval, dateForamt: String = "dd MMM yyyy hh:mm a") -> String {
        
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateForamt
        return dateFormatter.string(from: date)
    }
    
    private func decorateWithPadding(string: String, columnSize: Int) -> String {
        
        if string.count > columnSize {
            return String(string.prefix(columnSize))
        }
        
        let spaceCount = columnSize - string.count
        let spaceString = String(repeating: " ", count: spaceCount)
        return string + spaceString
    }
    
}

