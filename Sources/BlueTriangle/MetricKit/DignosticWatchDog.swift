//
//  DignosticWatchDog.swift
//  Matric Dignostic
//
//  Created by JP on 28/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

#if os(iOS)
import Foundation
import MetricKit
import UIKit

struct SavedTimer: Codable {
    let pageName: String
    let startTime: Double
    let sessionId: Identifier
}

class MetricKitWatchDog {
    
    private(set) var subscription = MetricKitSubscriber()
    
    init() {
        savePreviousPageData()
    }
    
    private func savePreviousPageData() {
        if let currentTimerDetail = UserDefaultsUtility.getData(type: Data.self, forKey: .currentTimerDetail),
           let decoded = try? JSONDecoder().decode(SavedTimer.self, from: currentTimerDetail){
           
            saveCrashedPageData(timerDetail: decoded)
        }
    }
    
    private func saveCrashedPageData(timerDetail: SavedTimer) {
        
        if let savedTimersData = UserDefaultsUtility.getData(type: Data.self, forKey: .savedTimers),
           var savedTimers = try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData),
           !savedTimers.isEmpty {
           
            savedTimers.append(timerDetail)
           
            if let encoded = try? JSONEncoder().encode(savedTimers) {
                UserDefaultsUtility.setData(value: encoded, key: .savedTimers)
            }
        }
        else if let encoded = try? JSONEncoder().encode([timerDetail]) {
            UserDefaultsUtility.setData(value: encoded, key: .savedTimers)
        }
    }
    
    func start(){
        
        if #available(iOS 14.0, *) {
            let pastDiagnosticPayloads = MXMetricManager.shared.pastDiagnosticPayloads
            
            NSLog("#\(#function) Previous reports \(pastDiagnosticPayloads)")
            subscription.setupDignoseDataInReporter(payloads: pastDiagnosticPayloads)
        }
        
        MXMetricManager.shared.add(subscription)
        addAppStateObservers()
    }
    
    private func addAppStateObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func applicationResignActive() {
       
        UserDefaultsUtility.removeData(key: .currentTimerDetail)
    }
    
    func saveCurrentTimerData(_ timer: BTTimer) {
        let timerDetail = SavedTimer(pageName: timer.page.pageName, startTime: Date().timeIntervalSince1970, sessionId: BlueTriangle.sessionID)
        if let encoded = try? JSONEncoder().encode(timerDetail) {
            UserDefaultsUtility.setData(value: encoded, key: .currentTimerDetail)
            UserDefaults.standard.synchronize()
        }
    }
    
    deinit {
        NSLog("#\(type(of: self)) \(#function) \(#line)")
    }
}

// MARK: - MXMetricManager Subscriber and Delegate
class MetricKitSubscriber: NSObject, MXMetricManagerSubscriber {
    
    private var formattedCrashReportString = ""
    
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Process metrics.l
        NSLog("# Received norma payload report \(#function)")
        
    }
    
    @available(iOS 14.0, *)
    func didReceive(_ payloads: [MXDiagnosticPayload]){
        
        let timerDetail =  getSavedTimer()
        NSLog("Crash reported by metric kit for session : %d , page : %@", timerDetail.sessionId, timerDetail.pageName)
        setupDignoseDataInReporter(payloads: payloads)
    }
}

// MARK: - Setup recieved payload
extension MetricKitSubscriber {
    
    @available(iOS 14.0, *)
    func setupDignoseDataInReporter(payloads: [MXDiagnosticPayload]) {
        
        NSLog("#Received Diagnostic report \(payloads)")
        
        for report in payloads {
            
            for crashReport in report.crashDiagnostics ?? []{
                
                createCrashReportModel(from: crashReport.jsonRepresentation(),
                                       terminationReason: crashReport.terminationReason ?? "Null",
                                       virtualMemoryRegionInfo: crashReport.virtualMemoryRegionInfo ?? "Null")
            }
        }
    }
    
}

// MARK: - Create Crash Models
extension MetricKitSubscriber {
    
   private func createCrashReportModel(from data: Data,
                                terminationReason: String,
                                virtualMemoryRegionInfo: String) {
        NSLog(#function)
        if let crashDataModel = decodeJsonResponse(data: data,
                                                   responseType: MetricKitCrashReport.self) {
            let timerDetail =  getAndUpdateSavedTopTimerDetail()
            saveRportToPresistence(report: crashDataModel,
                                   terminationReason: terminationReason,
                                   virtualMemoryRegionInfo: virtualMemoryRegionInfo,
                                   timerDetail: timerDetail)
            
            NSLog("#Save crash data in Presistence ")
            
        }
    }
    
    
    private func getSavedTimer() -> SavedTimer {
        if let savedTimersData = UserDefaultsUtility.getData(type: Data.self, forKey: .savedTimers),
           let savedTimers = try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData),!savedTimers.isEmpty,let timer = savedTimers.first {
            return timer
        }
        else {
            return SavedTimer(pageName: Constants.crashID, startTime: Date().timeIntervalSince1970, sessionId: BlueTriangle.sessionID)
        }
    }
    
    private func getAndUpdateSavedTopTimerDetail() -> SavedTimer {
        
        if let savedTimersData = UserDefaultsUtility.getData(type: Data.self, forKey: .savedTimers),
           var savedTimers = try? JSONDecoder().decode([SavedTimer].self, from: savedTimersData),
           !savedTimers.isEmpty,
           let timer = savedTimers.first {
           
            savedTimers.removeFirst()
            if let encoded = try? JSONEncoder().encode(savedTimers) {
                UserDefaultsUtility.setData(value: encoded, key: .savedTimers)
            }
            
            return timer
        }
        else {
            return SavedTimer(pageName: Constants.crashID, startTime: Date().timeIntervalSince1970, sessionId: BlueTriangle.sessionID)
        }
    }
}

// MARK: Create and Save formatted report to presistance
extension MetricKitSubscriber {
    
    private  func saveRportToPresistence(report: MetricKitCrashReport,
                                         terminationReason: String,
                                         virtualMemoryRegionInfo: String,
                                         timerDetail: SavedTimer) {
        
        var metaDataString = ""
       
        let crashTime = "~~ CrashTime: \(getFormattedDateString(timeInterval: timerDetail.startTime))"
        let reportTime = "~~ ReportTime: \(getFormattedDateString(timeInterval: Date().timeIntervalSince1970))"
        
        metaDataString = metaDataString + crashTime + reportTime
        metaDataString = metaDataString + "~~ " + getFormattedMetaData(metaData: report.diagnosticMetaData)
        metaDataString = metaDataString + "~~ " + "TerminationReason: \(terminationReason)"
        metaDataString = metaDataString + "~~ " + "VMReason: \(virtualMemoryRegionInfo)"
        metaDataString = metaDataString + "~~ ~~ Traces"
        
        formattedCrashReportString += metaDataString
        getForamttedStringOfCallStacks(report: report)
        
        print(formattedCrashReportString)
        
        let crashReport  = CrashReport(sessionID: timerDetail.sessionId,
                                       message: formattedCrashReportString,
                                       pageName: timerDetail.pageName,
                                       intervalProvider: timerDetail.startTime)
        
       CrashReportPersistence.saveCrash(crashReport: crashReport)
    }
    
    private func getForamttedStringOfCallStacks(report: MetricKitCrashReport) {
        
        let callStacks = report.callStackTree.callStacks
        
        for (callStack, threadNumber) in  zip(callStacks, 0..<callStacks.count) {
            
            let crashedText = callStack.threadAttributed ? "Crashed" : ""
            let threadDetail = "~~ ~~ Thread \(threadNumber) \(crashedText)"
            
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
        
        let hexAddress = String(subFrames.address, radix: 16, uppercase: true)
        let address = decorateWithPadding(string: "+ \(hexAddress)", columnSize: 20)
        
        let hexOffsetIntoBinaryTextSegment = String(subFrames.offsetIntoBinaryTextSegment, radix: 16, uppercase: true)
        let offsetIntoBinaryTextSegment = decorateWithPadding(string: "+ \(hexOffsetIntoBinaryTextSegment)", columnSize: 20)
       
        let string = "\n \(binaryName)  0x\(address)  0x\(offsetIntoBinaryTextSegment)"
        
        formattedCrashReportString += string
    }
    
    private func getFormattedMetaData(metaData: DiagnosticMetaData) -> String {
        
        var metaDataString = ""
        
        let applicationBuildVersion = "ApplicationBuildVersion: \(metaData.appBuildVersion)"
        metaDataString = metaDataString + applicationBuildVersion
        
        let deviceType = "DeviceType: \(metaData.deviceType)"
        metaDataString = metaDataString + "~~ " + deviceType
        
        var isTestFlightAppString = ""
        
        if let isTestFlightApp = metaData.isTestFlightApp {
            
            isTestFlightAppString = "isTestFlightApp: \(isTestFlightApp ? "true" : "false")"
        }
        else {
            
            isTestFlightAppString = "isTestFlightApp: Null"
        }
        metaDataString = metaDataString + "~~ " + isTestFlightAppString
        
        var lowPowerModeEnabledString = ""
        
        if let lowPowerModeEnabled = metaData.lowPowerModeEnabled {
            
            lowPowerModeEnabledString = "lowPowerModeEnabled: \(lowPowerModeEnabled ? "true" : "false")"
        }
        else {
            lowPowerModeEnabledString = "lowPowerModeEnabled: Null"
        }
        
        metaDataString = metaDataString + "~~ " + lowPowerModeEnabledString
        
        let osVersion = "osVersion: \(metaData.osVersion)"
        metaDataString = metaDataString + "~~ " + osVersion
        
        let platformArchitecture = "platformArchitecture: \(metaData.platformArchitecture)"
        metaDataString = metaDataString + "~~ " + platformArchitecture
        
        let regionFormat = "regionFormat: \(metaData.regionFormat)"
        metaDataString = metaDataString + "~~ " + regionFormat
        
        let exceptionType = "ExceptionType: \(metaData.exceptionType)"
        metaDataString = metaDataString + "~~ " + exceptionType
        
        let exceptionCode = "ExceptionCode: \(metaData.exceptionCode)"
        metaDataString = metaDataString + "~~ " + exceptionCode
        
        let signal = "Signal: \(CrashSignal.getSignalNumbeDetail(signal: metaData.signal))"
        metaDataString = metaDataString + "~~ " + signal
        
        return metaDataString
    }
    
}

// MARK: Helper Methods
extension MetricKitSubscriber {
    
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
    
    func getFormattedDateString(timeInterval: TimeInterval, dateForamt: String = "dd MMM yyyy hh:mm a") -> String {
      
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
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

#endif
