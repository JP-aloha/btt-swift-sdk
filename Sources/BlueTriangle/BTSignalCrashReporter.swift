//
//  BTCrashReporter.swift
//
//
//  Created by Ashok Singh on 01/07/24.
//

import Foundation
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
    var btt_session_id: String?
    var btt_page_name: String?
    var trafic_segment: String
    var page_type: String
    var breadcrumbs: String?
}

class BTSignalCrashReporter {

    private let directory: String

    private let logger: Logging

    init(
        directory: String,
        logger: Logging
    ) {
        self.directory = directory
        self.logger = logger
    }

    func configureSignalCrashHandling(configuration: CrashReportConfiguration) {
        switch configuration {
        case .nsException:
            savePendingRecordsForStoredCrashes()
        }
    }

    private func savePendingRecordsForStoredCrashes() {
        guard let crashes = try? getAllCrashes() else { return }
        for crash in crashes {
            guard let sessionIdText = crash.btt_session_id, !sessionIdText.isEmpty, let sessionId = UInt64(sessionIdText) else {
                try? removeFile(crash)
                continue
            }
            let pageName = (crash.btt_page_name ?? "").isEmpty ? nil : crash.btt_page_name
            let trafficSegment = crash.trafic_segment.isEmpty ? nil : crash.trafic_segment
            let pageType = crash.page_type.isEmpty ? nil : crash.page_type
            PendingCrashRecordStore.save(PendingCrashRecord(sessionID: sessionId,
                                                             pageName: pageName,
                                                             trafficSegment: trafficSegment,
                                                             pageType: pageType,
                                                             breadcrumbs: crash.breadcrumbs,
                                                             crashTime: Millisecond(crash.crash_time) * 1000),
                                         key: .pendingCrashRecord)
            try? removeFile(crash)
        }
    }

    func stop(){
        SignalHandler.disableCrashTracking()
        self.removeAllCrashes()
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

    private  func getAllCrashes() throws -> [SignalCrash]{

        var crashes = [SignalCrash]()
        let files = try self.getAllFiles()

        for file in files {
            guard let crashData = try self.readFile(file) else { return crashes}
            crashes.append(crashData)
        }

        return crashes
    }

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

    private  func removeAllCrashes(){
        do{
            let crashes = try self.getAllCrashes()
            for crash in crashes {
                try self.removeFile(crash)
            }
        }catch{
            logger.error("BlueTriangle:SignalCrashReporter: \(error.localizedDescription)")
        }
    }
}
