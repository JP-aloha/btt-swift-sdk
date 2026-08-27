//
//  CrashReportManagerTests.swift
//
//  Created by Mathew Gacy on 3/28/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class CrashReportManagerTests: XCTestCase {
    struct TestError: Error {
        let message = "There as an error"
        
        var errorDescription: String? {
            message
        }
    }
    
    let crashErrorReport = ErrorReport(eCnt: 1, nativeApp:  NativeAppProperties(
        fullTime: 0,
        loadTime: 0,
        loadStartTime: 0,
        loadEndTime: 0,
        maxMainThreadUsage: 0,
        screenType: nil,
        offline: 0,
        wifi:  0,
        cellular:  0,
        ethernet:  0,
        other:  0, 
        netState: NetworkState.Other.description),
        eTp: BT_ErrorType.NativeAppCrash.rawValue,
                                       message: "crash_message",
                                       line: 1, column: 2,
                                       time: 100)
    var crashReport: CrashReport {
        .init(sessionID: 100_000_000_000_000_001, pageName: "CrashReportManagerTests", report: crashErrorReport, segment: "Main Segment", pageType: "Main Group")
    }

    override func setUp() {
        super.setUp()
        CrashReportPersistenceMock.reset()
        _ = PendingCrashRecordStore.consume(matchingCrashTime: nil)
    }

    override func tearDown() {
        super.tearDown()
        CrashReportPersistenceMock.reset()
        _ = PendingCrashRecordStore.consume(matchingCrashTime: nil)
    }

    /// Reporting a persisted native crash is MetricKit's job now - init() should just stash its
    /// session/page context in `PendingCrashRecordStore` for `MetricKitWatchDog` to pick up, then
    /// clear the persisted report since nothing else will consume it.
    func testReportStoredAsPendingRecordAndClearedOnInit() {
        let reportReadExpectation = expectation(description: "Crash report read")
        let reportClearedExpectation = expectation(description: "Crash report cleared")
        CrashReportPersistenceMock.configure(
            onRead: {
                reportReadExpectation.fulfill()
                return self.crashReport
            },
            onClear: { reportClearedExpectation.fulfill() })

        _ = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: UploaderMock(),
            session: Mock.sessionProvider)

        wait(for: [reportReadExpectation, reportClearedExpectation], timeout: 1.0)

        let pending = PendingCrashRecordStore.consume(matchingCrashTime: nil)
        XCTAssertEqual(pending?.sessionID, crashReport.sessionID)
        XCTAssertEqual(pending?.pageName, crashReport.pageName)
    }

    func testNoPendingRecordSavedWhenNoReportPersisted() {
        CrashReportPersistenceMock.configure(onRead: { nil }, onClear: {})

        _ = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: UploaderMock(),
            session: Mock.sessionProvider)

        XCTAssertNil(PendingCrashRecordStore.consume(matchingCrashTime: nil))
    }

    func testErrorTimerUploaded() throws {
        let expectedErrorStart: TimeInterval = 1000.0
        CrashReportPersistenceMock.configure(onRead: { nil }, onClear: {})

        var timerRequest: Request!
        let uploadExpectation = expectation(description: "Timer uploaded")
        let uploader = UploaderMock { request in
            if timerRequest == nil {
                timerRequest = request
                uploadExpectation.fulfill()
            }
        }

        let sut = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: uploader,
            session: Mock.sessionProvider,
            intervalProvider: { expectedErrorStart }
        )

        sut.uploadError(TestError(), file: #file, function: #function, line: #line)
        wait(for: [uploadExpectation], timeout: 1.0)

        let actualTimer = try JSONDecoder().decode(TimerRequest.self, from: timerRequest.body!.base64DecodedData()!)
        XCTAssertEqual(actualTimer.session.sessionID, Mock.sessionID)
        XCTAssertEqual(actualTimer.timer.startTime, expectedErrorStart.milliseconds)
    }

    func testErrorReportUploaded() throws {
        let expectedErrorStart: TimeInterval = 1000.0
        let expectedMessage = TestError().localizedDescription
        CrashReportPersistenceMock.configure(onRead: { nil }, onClear: {})

        var requestCount = 0
        var errorRequest: Request!
        let uploadExpectation = expectation(description: "Report uploaded")
        let uploader = UploaderMock { request in
            requestCount += 1
            if requestCount > 1 {
                errorRequest = request
                uploadExpectation.fulfill()
            }
        }

        let sut = CrashReportManager(
            crashReportPersistence: CrashReportPersistenceMock.self,
            logger: LoggerMock(),
            uploader: uploader,
            session: Mock.sessionProvider,
            intervalProvider: { expectedErrorStart }
        )

        sut.uploadError(TestError(), file: #file, function: #function, line: #line)
        wait(for: [uploadExpectation], timeout: 1.0)

        let actualReport = try JSONDecoder().decode([ErrorReport].self,from: errorRequest.body!.base64DecodedData()!).first!

        XCTAssertEqual(errorRequest.parameters!["nStart"], "\(expectedErrorStart.milliseconds)")
        XCTAssertEqual(errorRequest.parameters!["sessionID"], "\(Mock.sessionID)")

        XCTAssertEqual(actualReport.message, expectedMessage)
        XCTAssertEqual(actualReport.time, expectedErrorStart.milliseconds)
    }
}

