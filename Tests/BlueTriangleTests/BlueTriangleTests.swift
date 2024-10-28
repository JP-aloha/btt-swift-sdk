//
//  BlueTriangleTests.swift
//
//  Created by Mathew Gacy on 1/27/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
import Combine
@testable import BlueTriangle

// swiftlint:disable function_body_length
final class BlueTriangleTests: XCTestCase {
    static let requestEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]        
        return encoder
    }()

    static var timeIntervals: [TimeInterval] = []
    static let timeIntervalProvider: () -> TimeInterval = {
        timeIntervals.popLast() ?? 0
    }
    static let session = Mock.session
    static let logger = LoggerMock()
    static let performanceMonitor = PerformanceMonitorMock()
  
    static var onMakeTimer: (Page, BTTimer.TimerType) -> Void = { _, _ in }
    static let timerFactory: (Page, BTTimer.TimerType) -> BTTimer = { page, timerType in
        onMakeTimer(page, timerType)
        return BTTimer(
            page: page,
            type: timerType,
            logger: logger,
            intervalProvider: timeIntervalProvider,
            performanceMonitor: performanceMonitor)
    }

    static var onBuildRequest: (Session, BTTimer, PurchaseConfirmation?) throws -> Void = { _, _, _ in }
    static let requestBuilder = TimerRequestBuilder { session, timer, purchaseConfirmation in
        try onBuildRequest(session, timer, purchaseConfirmation)
        let model = TimerRequest(session: session,
                                 page: timer.page,
                                 timer: timer.pageTimeInterval,
                                 purchaseConfirmation: purchaseConfirmation,
                                 performanceReport: timer.performanceReport)

        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           model: model,
                           encode: {
            try requestEncoder.encode($0).base64EncodedData()
            
        })
    }
    
   // static capture = C
    
    static func makeBuilder(sessionProvider: @escaping () -> Session) -> CapturedRequestBuilder {
        CapturedRequestBuilder { startTime, page, requests in
            let session = sessionProvider()
            let parameters = CapturedRequestBuilder.makeParameters(
                siteID: session.siteID,
                sessionID: String(session.sessionID),
                trafficSegment: session.trafficSegmentName,
                isNewUser: !session.isReturningVisitor,
                pageType: page.pageType,
                pageName: page.pageName,
                startTime: startTime
            )

            return try Request(method: .post,
                               url: Constants.capturedRequestEndpoint,
                               parameters: parameters,
                               model: requests,
                               encode: {
                try requestEncoder.encode($0).base64EncodedData()
            
            })
        }
    }

    static var onSendRequest: (Request) -> Void = { _ in }
    static let uploader = UploaderMock { onSendRequest($0) }

    override class func tearDown() {
        super.tearDown()
        BlueTriangle.reset()
        Self.onSendRequest = { _ in }
    }

    override func tearDown() {
        super.tearDown()
        Self.timeIntervals = []
        Self.onMakeTimer = { _, _ in }
        Self.onBuildRequest = { _, _, _ in }
        Self.onSendRequest = { _ in }
        Self.logger.reset()
        Self.performanceMonitor.reset()
        BlueTriangle.reset()
    }
}

// MARK: - Timer
extension BlueTriangleTests {
    
#if os(iOS) || os(macOS)
    
    func testMakeTimer() throws {
        let expectedInitialState: BTTimer.State = .initial
        let expectedStartTime: TimeInterval = 0
        let expectedInteractiveTime: TimeInterval = 1000
        let expectedEndTime: TimeInterval = 2000

        Self.timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime
        ]

        // Performance Monitor
        let performanceStartExpectation = expectation(description: "Performance monitoring started")
        let performanceEndExpectation = expectation(description: "Performance monitoring ended")
        let expectedReport = Mock.performanceReport

        Self.performanceMonitor.report = expectedReport
        Self.performanceMonitor.onStart = { performanceStartExpectation.fulfill() }
        Self.performanceMonitor.onEnd = { performanceEndExpectation.fulfill() }

        // Request Builder
        var finishedTimer: BTTimer!
        Self.onBuildRequest = { _, timer, _ in
            finishedTimer = timer
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            session: Self.session,
            logger: Self.logger,
            uploader: Self.uploader,
            timerFactory: Self.timerFactory,
            shouldCaptureRequests: false,
            requestCollector: nil
        )

        // Timer
        let timer = BlueTriangle.makeTimer(page: Mock.page)
        XCTAssertEqual(timer.state, expectedInitialState)

        timer.start()
        timer.markInteractive()
        BlueTriangle.endTimer(timer)
        
        XCTAssertNotNil(finishedTimer)
        XCTAssertEqual(finishedTimer.startTime, expectedStartTime)
        XCTAssertEqual(finishedTimer.interactiveTime, expectedInteractiveTime)
        XCTAssertEqual(finishedTimer.endTime, expectedEndTime)

        waitForExpectations(timeout: 5.0)

        let base64Decoded = Data(base64Encoded: request.body!)!
        
        let timerRequest = try JSONDecoder().decode(TimerRequest.self, from: base64Decoded)
                
        let appVersion = Bundle.main.releaseVersionNumber ?? "0.0"
        XCTAssertEqual(timerRequest.session.abTestID, "MY_AB_TEST_ID")
        XCTAssertEqual(timerRequest.session.campaign, nil)
        XCTAssertEqual(timerRequest.session.campaignName, "MY_CAMPAIGN_NAME")
        XCTAssertEqual(timerRequest.session.campaignMedium, "MY_CAMPAIGN_MEDIUM")
        XCTAssertEqual(timerRequest.session.campaignSource, "MY_CAMPAIGN_SOURCE")
        XCTAssertEqual(timerRequest.session.appVersion, "Native App-\(appVersion)-\(Device.os) \(Device.osVersion)")
        XCTAssertEqual(timerRequest.session.wcd, 1)
        XCTAssertEqual(timerRequest.session.eventType, 9)
        XCTAssertEqual(timerRequest.session.navigationType, 9)
        XCTAssertEqual(timerRequest.session.sessionID, 999999999999999999)
        XCTAssertEqual(timerRequest.session.siteID, "MY_SITE_ID")
        XCTAssertEqual(timerRequest.session.dataCenter, "MY_DATA_CENTER")
        XCTAssertEqual(timerRequest.session.trafficSegmentName, "MY_SEGMENT_NAME")
        XCTAssertEqual(timerRequest.session.isReturningVisitor,true)
        XCTAssertEqual(timerRequest.session.osInfo, Device.os)
        XCTAssertEqual(timerRequest.session.globalUserID,888888888888888888)
        
        
        XCTAssertEqual(timerRequest.page.pageName, "MY_PAGE_NAME")
        XCTAssertEqual(timerRequest.page.pageType, "MY_PAGE_TYPE")
        XCTAssertEqual(timerRequest.page.referringURL, "MY_REFERRING_URL")
        XCTAssertEqual(timerRequest.page.brandValue, 0.51)
        XCTAssertEqual(timerRequest.page.url, "MY_URL")
        XCTAssertEqual(timerRequest.page.referringURL, "MY_REFERRING_URL")
        
     
        
        if let cv = timerRequest.page.customVariables {
            XCTAssertEqual(cv.cv1, "CV1")
            XCTAssertEqual(cv.cv2, "CV2")
            XCTAssertEqual(cv.cv3, "CV3")
            XCTAssertEqual(cv.cv4, "CV4")
            XCTAssertEqual(cv.cv5, "CV5")
            XCTAssertEqual(cv.cv11, "CV11")
            XCTAssertEqual(cv.cv12, "CV12")
            XCTAssertEqual(cv.cv13, "CV13")
            XCTAssertEqual(cv.cv14, "CV14")
            XCTAssertEqual(cv.cv15, "CV15")
            XCTAssertEqual(cv.cv1, "CV1")
        }
        
        if let cv = timerRequest.page.customCategories {
            XCTAssertEqual(cv.cv6, "CV6")
            XCTAssertEqual(cv.cv7, "CV7")
            XCTAssertEqual(cv.cv8, "CV8")
            XCTAssertEqual(cv.cv9, "CV9")
            XCTAssertEqual(cv.cv10, "CV10")
        }
        
        
        if let cn = timerRequest.page.customNumbers {
            XCTAssert( cn.cn1 == 1.11 || cn.cn1 == 1.1100000000000001)
            XCTAssert( cn.cn2 == 2.22 || cn.cn2 == 2.2200000000000002)
            XCTAssert( cn.cn3 == 3.33 || cn.cn3 == 3.3300000000000001)
            XCTAssert( cn.cn4 == 4.44 || cn.cn4 == 4.4400000000000004)
            XCTAssert( cn.cn5 == 5.55 || cn.cn5 == 5.5499999999999998)
            XCTAssert( cn.cn6 == 6.66 || cn.cn6 == 6.6600000000000001)
            XCTAssert( cn.cn7 == 7.77 || cn.cn7 == 7.7699999999999996)
            XCTAssert( cn.cn8 == 8.88 || cn.cn8 == 8.8800000000000008)
            XCTAssert( cn.cn9 == 9.99 || cn.cn9 == 9.9900000000000002)
            XCTAssert( cn.cn10 == 10.1 || cn.cn10 == 10.1)
            XCTAssert( cn.cn11 == 11.11 || cn.cn11 == 11.109999999999999)
            XCTAssert( cn.cn12 == 12.12 || cn.cn12 == 12.119999999999999)
            XCTAssert( cn.cn13 == 13.13 || cn.cn13 == 13.130000000000001)
            XCTAssert( cn.cn14 == 14.14 || cn.cn14 == 14.140000000000001)
            XCTAssert( cn.cn15 == 15.15 || cn.cn15 == 15.15)
            XCTAssert( cn.cn16 == 16.16 || cn.cn16 == 16.16)
            XCTAssert( cn.cn17 == 17.17 || cn.cn17 == 17.170000000000002)
            XCTAssert( cn.cn18 == 18.18 || cn.cn18 == 18.18)
            XCTAssert( cn.cn19 == 19.19 || cn.cn19 == 19.190000000000001)
            XCTAssert( cn.cn20 == 20.211 || cn.cn20 == 20.199999999999999)
        }
        
        if let pr = timerRequest.performanceReport {
            XCTAssertEqual(pr.avgCPU, 50)
            XCTAssertEqual(pr.minCPU, 1)
            XCTAssertEqual(pr.maxCPU, 100)
            
            XCTAssertEqual(pr.avgMemory, 50000000)
            XCTAssertEqual(pr.minMemory, 10000000)
            XCTAssertEqual(pr.maxMemory, 100000000)
        }
        
        XCTAssertEqual(timerRequest.timer.pageTime, 2000000)
        XCTAssertEqual(timerRequest.timer.startTime, 0)
        XCTAssertEqual(timerRequest.timer.unloadStartTime, 0)
        XCTAssertEqual(timerRequest.timer.interactiveTime, 1000000)

    }

    func testStartTimer() throws {
        let expectedInitialState: BTTimer.State = .started
        let expectedStartTime: TimeInterval = 0
        let expectedInteractiveTime: TimeInterval = 1000
        let expectedEndTime: TimeInterval = 2000

        Self.timeIntervals = [
            expectedEndTime,
            expectedInteractiveTime,
            expectedStartTime
        ]

        // Performance Monitor
        let performanceStartExpectation = expectation(description: "Performance monitoring started")
        let performanceEndExpectation = expectation(description: "Performance monitoring ended")
        let expectedReport = PerformanceReport(minCPU: 1.0,
                                               maxCPU: 100.0,
                                               avgCPU: 50.0,
                                               minMemory: 10000000,
                                               maxMemory: 100000000,
                                               avgMemory: 50000000)

        Self.performanceMonitor.report = expectedReport
        Self.performanceMonitor.onStart = { performanceStartExpectation.fulfill() }
        Self.performanceMonitor.onEnd = { performanceEndExpectation.fulfill() }

        // Request Builder
        var finishedTimer: BTTimer!
        Self.onBuildRequest = { _, timer, _ in
            finishedTimer = timer
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            session: Self.session,
            logger: Self.logger,
            uploader: Self.uploader,
            timerFactory: Self.timerFactory,
            shouldCaptureRequests: false,
            requestCollector: nil
        )

        // Timer
        let timer = BlueTriangle.startTimer(page: Mock.page)
        XCTAssertEqual(timer.state, expectedInitialState)

        timer.markInteractive()
        BlueTriangle.endTimer(timer)

        XCTAssertNotNil(finishedTimer)
        XCTAssertEqual(finishedTimer.startTime, expectedStartTime)
        XCTAssertEqual(finishedTimer.interactiveTime, expectedInteractiveTime)
        XCTAssertEqual(finishedTimer.endTime, expectedEndTime)

        waitForExpectations(timeout: 5.0)

        let base64Decoded = Data(base64Encoded: request.body!)!
        
        let timerRequest = try JSONDecoder().decode(TimerRequest.self, from: base64Decoded)
                
        let appVersion = Bundle.main.releaseVersionNumber ?? "0.0"
        XCTAssertEqual(timerRequest.session.abTestID, "MY_AB_TEST_ID")
        XCTAssertEqual(timerRequest.session.campaign, nil)
        XCTAssertEqual(timerRequest.session.campaignName, "MY_CAMPAIGN_NAME")
        XCTAssertEqual(timerRequest.session.campaignMedium, "MY_CAMPAIGN_MEDIUM")
        XCTAssertEqual(timerRequest.session.campaignSource, "MY_CAMPAIGN_SOURCE")
        XCTAssertEqual(timerRequest.session.appVersion, "Native App-\(appVersion)-\(Device.os) \(Device.osVersion)")
        XCTAssertEqual(timerRequest.session.wcd, 1)
        XCTAssertEqual(timerRequest.session.eventType, 9)
        XCTAssertEqual(timerRequest.session.navigationType, 9)
        XCTAssertEqual(timerRequest.session.sessionID, 999999999999999999)
        XCTAssertEqual(timerRequest.session.siteID, "MY_SITE_ID")
        XCTAssertEqual(timerRequest.session.dataCenter, "MY_DATA_CENTER")
        XCTAssertEqual(timerRequest.session.trafficSegmentName, "MY_SEGMENT_NAME")
        XCTAssertEqual(timerRequest.session.isReturningVisitor,true)
        XCTAssertEqual(timerRequest.session.osInfo, Device.os)
        XCTAssertEqual(timerRequest.session.globalUserID,888888888888888888)
        
        
        XCTAssertEqual(timerRequest.page.pageName, "MY_PAGE_NAME")
        XCTAssertEqual(timerRequest.page.pageType, "MY_PAGE_TYPE")
        XCTAssertEqual(timerRequest.page.referringURL, "MY_REFERRING_URL")
        XCTAssertEqual(timerRequest.page.brandValue, 0.51)
        XCTAssertEqual(timerRequest.page.url, "MY_URL")
        XCTAssertEqual(timerRequest.page.referringURL, "MY_REFERRING_URL")
        
     
        
        if let cv = timerRequest.page.customVariables {
            XCTAssertEqual(cv.cv1, "CV1")
            XCTAssertEqual(cv.cv2, "CV2")
            XCTAssertEqual(cv.cv3, "CV3")
            XCTAssertEqual(cv.cv4, "CV4")
            XCTAssertEqual(cv.cv5, "CV5")
            XCTAssertEqual(cv.cv11, "CV11")
            XCTAssertEqual(cv.cv12, "CV12")
            XCTAssertEqual(cv.cv13, "CV13")
            XCTAssertEqual(cv.cv14, "CV14")
            XCTAssertEqual(cv.cv15, "CV15")
            XCTAssertEqual(cv.cv1, "CV1")
        }
        
        if let cv = timerRequest.page.customCategories {
            XCTAssertEqual(cv.cv6, "CV6")
            XCTAssertEqual(cv.cv7, "CV7")
            XCTAssertEqual(cv.cv8, "CV8")
            XCTAssertEqual(cv.cv9, "CV9")
            XCTAssertEqual(cv.cv10, "CV10")
        }
        
        
        if let cn = timerRequest.page.customNumbers {
            XCTAssert( cn.cn1 == 1.11 || cn.cn1 == 1.1100000000000001)
            XCTAssert( cn.cn2 == 2.22 || cn.cn2 == 2.2200000000000002)
            XCTAssert( cn.cn3 == 3.33 || cn.cn3 == 3.3300000000000001)
            XCTAssert( cn.cn4 == 4.44 || cn.cn4 == 4.4400000000000004)
            XCTAssert( cn.cn5 == 5.55 || cn.cn5 == 5.5499999999999998)
            XCTAssert( cn.cn6 == 6.66 || cn.cn6 == 6.6600000000000001)
            XCTAssert( cn.cn7 == 7.77 || cn.cn7 == 7.7699999999999996)
            XCTAssert( cn.cn8 == 8.88 || cn.cn8 == 8.8800000000000008)
            XCTAssert( cn.cn9 == 9.99 || cn.cn9 == 9.9900000000000002)
            XCTAssert( cn.cn10 == 10.1 || cn.cn10 == 10.1)
            XCTAssert( cn.cn11 == 11.11 || cn.cn11 == 11.109999999999999)
            XCTAssert( cn.cn12 == 12.12 || cn.cn12 == 12.119999999999999)
            XCTAssert( cn.cn13 == 13.13 || cn.cn13 == 13.130000000000001)
            XCTAssert( cn.cn14 == 14.14 || cn.cn14 == 14.140000000000001)
            XCTAssert( cn.cn15 == 15.15 || cn.cn15 == 15.15)
            XCTAssert( cn.cn16 == 16.16 || cn.cn16 == 16.16)
            XCTAssert( cn.cn17 == 17.17 || cn.cn17 == 17.170000000000002)
            XCTAssert( cn.cn18 == 18.18 || cn.cn18 == 18.18)
            XCTAssert( cn.cn19 == 19.19 || cn.cn19 == 19.190000000000001)
            XCTAssert( cn.cn20 == 20.211 || cn.cn20 == 20.199999999999999)
        }
        
        if let pr = timerRequest.performanceReport {
            XCTAssertEqual(pr.avgCPU, 50)
            XCTAssertEqual(pr.minCPU, 1)
            XCTAssertEqual(pr.maxCPU, 100)
            
            XCTAssertEqual(pr.avgMemory, 50000000)
            XCTAssertEqual(pr.minMemory, 10000000)
            XCTAssertEqual(pr.maxMemory, 100000000)
        }
        
        XCTAssertEqual(timerRequest.timer.pageTime, 2000000)
        XCTAssertEqual(timerRequest.timer.startTime, 0)
        XCTAssertEqual(timerRequest.timer.unloadStartTime, 0)
        XCTAssertEqual(timerRequest.timer.interactiveTime, 1000000)

      //  XCTAssert((requestString?.isEqual(expectedString1) ?? false) || (requestString?.isEqual(expectedString2) ?? false))
    }
#endif
}


// MARK: - Network Capture
extension BlueTriangleTests {
    func testNetworkCapture() async throws {
        Self.timeIntervals = [
            // BTTimer.start()
            6.0,
            // BTTimer.end()
            5.0,
            // BTTimer.start()
            1.0
        ]

        var requestTimeIntervals = [
            // InternalTimer.end()
            4.0,
            // InternalTimer.start()
            3.0
        ]
        let requestTimerIntervalProvider = {
            requestTimeIntervals.popLast()!
        }

        // Timer
        let timerFactory: (Page, BTTimer.TimerType) -> BTTimer = { page, timerType in
            BTTimer(page: page,
                    type: timerType,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    onStart: BlueTriangle.timerDidStart(_:page:startTime:),
                    performanceMonitor: PerformanceMonitorMock())
        }

        // Uploader
        var capturedRequest: Request!
        var requestExpectation: XCTestExpectation?
        let capturedRequestUploader = UploaderMock { req in
            capturedRequest = req
            requestExpectation?.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        let requestCollector = Mock.makeRequestCollectorConfiguration()
            .makeRequestCollector(
                logger: Self.logger,
                networkCaptureConfiguration: .standard,
                requestBuilder: BlueTriangleTests.makeBuilder { Mock.session },
                uploader: capturedRequestUploader)

        BlueTriangle.reconfigure(
            configuration: configuration,
            uploader: Self.uploader,
            timerFactory: timerFactory,
            shouldCaptureRequests: true,
            internalTimerFactory: { InternalTimer(logger: Self.logger, intervalProvider: requestTimerIntervalProvider) },
            requestCollector: requestCollector)

        let timer = BlueTriangle.startTimer(page: Mock.page)
        
        let url: URL = "https://example.com/foo.json"
        let exp = expectation(description: "Requests completed")
        URLSession(configuration: .mock).btDataTask(with: url) { _, _, _ in exp.fulfill() }.resume()
        
        await waitForExpectations(timeout: 15.0)
        
        requestExpectation = self.expectation(description: "Request sent")
        
        timer.end()
        
        _ = BlueTriangle.startTimer(page: Page(pageName: "Another_Page"))
        await waitForExpectations(timeout: 15.0)

        let capturedRequestString = String(data: Data(base64Encoded: capturedRequest.body!)!, encoding: .utf8)

        let base64Decoded = Data(base64Encoded: capturedRequest.body!)!
        
        if  let performanceReport = try JSONDecoder().decode([CapturedRequest].self, from: base64Decoded).first {
            XCTAssertEqual(performanceReport.url, "https://example.com/foo.json")
            XCTAssertEqual(performanceReport.file, "foo.json")
            XCTAssertEqual(performanceReport.domain, "example.com")
            XCTAssertEqual(performanceReport.duration, 1000)
            XCTAssertEqual(performanceReport.decodedBodySize, -1)
            XCTAssertEqual(performanceReport.entryType, "resource")
            XCTAssertEqual(performanceReport.encodedBodySize, 0)
            XCTAssertEqual(performanceReport.host, "example")
            XCTAssertEqual(performanceReport.initiatorType, .other)
            XCTAssertEqual(performanceReport.statusCode, "200")
            XCTAssertEqual(performanceReport.endTime, 3000)
            XCTAssertEqual(performanceReport.startTime, 2000)
            print("Request : \(performanceReport)")
        }else{
            XCTFail()
        }
    }
}

// MARK: - Custom Metrics
extension BlueTriangleTests {
    func testSetNewMetricsValue() {
        let expectedMetrics: [String: String] = [
            "string": "String",
            "double": "9.99",
            "newKey" : "NewValue"
        ]

        var session = Mock.session
        
        session.metrics = [
            "string": "String",
            "double": 9.99
        ]
        
        BlueTriangle.reconfigure(session: session)

        BlueTriangle.setCustomVariable("newKey", value: "NewValue")

        let actualMetrics = BlueTriangle.getCustomVariables()
        XCTAssertEqual(actualMetrics, expectedMetrics)
    }

    func testRemoveMetricsValue() {
        let expectedMetrics: [String: String] = [
            "string": "String",
            "double": "9.99"
        ]

        var session = Mock.session
        session.metrics = [
            "string": "String",
            "double": 9.99,
            "newKey" : "NewValue"
        ]
        BlueTriangle.reconfigure(session: session)

        BlueTriangle.clearCustomVariable("newKey")

        let actualMetrics = BlueTriangle.getCustomVariables()
        XCTAssertEqual(actualMetrics, expectedMetrics)
    }

    func testSetAnyValue() {
        let key = "key"
        let value = "value"
        let expectedValue: [String: AnyCodable] = [key: .string(value)]

        BlueTriangle.reconfigure(session: Mock.session)

        BlueTriangle.setCustomVariable(key, value: value)
        let actualValue = BlueTriangle.getCustomVariable(key)

        XCTAssertEqual(actualValue, value)
    }

    func testSetNSNumber() {
        let key = "key"
        let double = 9.99
        let value = NSNumber(value: double)
        let expectedMetrics: [String: AnyCodable] = [key: .double(double)]

        BlueTriangle.reconfigure(session: Mock.session)

        BlueTriangle.setCustomVariable(key, value: value)
        let actualValue = BlueTriangle.getCustomVariable(key)
        
        XCTAssertEqual(actualValue, value.stringValue)
    }

    func testGetAny() {
        let key = "key"
        let expectedValue = 5
        let value = NSNumber(value: expectedValue)

        var session = Mock.session
        session.metrics = [key: .int(expectedValue)]
        BlueTriangle.reconfigure(session: session)

        let actualValue = BlueTriangle.getCustomVariable(key)
        XCTAssertEqual(actualValue, value.stringValue)
    }

    func testClearMetrics() {
        var session = Mock.session
        session.metrics = ["key": .int(5)]
        BlueTriangle.reconfigure(session: session)

        BlueTriangle.clearAllCustomVariables()
        let variables = BlueTriangle.getCustomVariables()
        XCTAssertEqual(variables, [:])
    }
}

#if os(iOS) || os(tvOS)
extension BlueTriangleTests {
    @available(iOS 14.0, tvOS 14.0, *)
    func testDisplayLinkPerformanceMonitor() throws {
        let performanceMonitor = DisplayLinkPerformanceMonitor(minimumSampleInterval: 0.1,
                                                               resourceUsage: ResourceUsage.self)

        // Timer
        let timerFactory: (Page, BTTimer.TimerType) -> BTTimer = { page, timerType  in
            BTTimer(page: page,
                    type: timerType,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    performanceMonitor: performanceMonitor)
        }

        // Request Builder
        var finishedTimer: BTTimer!
        Self.onBuildRequest = {  _, timer, _ in
            finishedTimer = timer
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            logger: Self.logger,
            uploader: Self.uploader,
            timerFactory: timerFactory,
            shouldCaptureRequests: false,
            requestCollector: nil
        )

        // ViewController
        let imageSize: CGSize = .init(width: 150, height: 150)
        let delayStragegy: DelayGenerator.Strategy = .random((mean: 1, variation: 0.5))
        let networkClient: NetworkClientMock = .makeClient(delayStrategy: delayStragegy,
                                                           imageSize: imageSize)
        let viewController = CollectionViewController(networkClient: networkClient)
        viewController.viewDidLoad()

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(finishedTimer)

        let base64Decoded = Data(base64Encoded: request.body!)!
        let performanceReport = try JSONDecoder().decode(TimerRequest.self, from: base64Decoded).performanceReport!
        XCTAssertNotEqual(performanceReport.maxCPU, 0.0)
        XCTAssertNotEqual(performanceReport.avgCPU, 0.0)
        XCTAssertNotEqual(performanceReport.minMemory, 0)
        XCTAssertNotEqual(performanceReport.maxMemory, 0)
        XCTAssertNotEqual(performanceReport.avgMemory, 0)
    }

    @available(iOS 14.0, tvOS 14.0, *)
    func testTimerPerformanceMonitor() throws {
        let performanceMonitor = TimerPerformanceMonitor(sampleInterval: 1 / 60,
                                                         resourceUsage: ResourceUsage.self)

        // Timer
        let timerFactory: (Page, BTTimer.TimerType) -> BTTimer = { page, timerType  in
            BTTimer(page: page,
                    type: timerType,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    performanceMonitor: performanceMonitor)
        }

        // Request Builder
        var finishedTimer: BTTimer!
        Self.onBuildRequest = {  _, timer, _ in
            finishedTimer = timer
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        var request: Request!
        Self.onSendRequest = { req in
            request = req
            requestExpectation.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            logger: Self.logger,
            uploader: Self.uploader,
            timerFactory: timerFactory,
            shouldCaptureRequests: false,
            requestCollector: nil
        )

        // ViewController
        let imageSize: CGSize = .init(width: 150, height: 150)
        let delayStragegy: DelayGenerator.Strategy = .random((mean: 1, variation: 0.5))
        let networkClient: NetworkClientMock = .makeClient(delayStrategy: delayStragegy,
                                                           imageSize: imageSize)
        let viewController = CollectionViewController(networkClient: networkClient)
        viewController.viewDidLoad()

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(finishedTimer)

        let base64Decoded = Data(base64Encoded: request.body!)!
        let performanceReport = try JSONDecoder().decode(TimerRequest.self, from: base64Decoded).performanceReport!
        XCTAssertNotEqual(performanceReport.maxCPU, 0.0)
        XCTAssertNotEqual(performanceReport.avgCPU, 0.0)
        XCTAssertNotEqual(performanceReport.minMemory, 0)
        XCTAssertNotEqual(performanceReport.maxMemory, 0)
        XCTAssertNotEqual(performanceReport.avgMemory, 0)
    }

    @available(iOS 14.0, tvOS 14.0, *)
    func testDispatchSourceTimerPerformanceMonitor() throws {
        let performanceMonitor = DispatchSourceTimerPerformanceMonitor(sampleInterval: 1 / 60,
                                                                       resourceUsage: ResourceUsage.self)

        // Timer
        let timerFactory: (Page, BTTimer.TimerType) -> BTTimer = { page, timerType  in
            BTTimer(page: page,
                    type: timerType,
                    logger: Self.logger,
                    intervalProvider: Self.timeIntervalProvider,
                    performanceMonitor: performanceMonitor)
        }

        // Request Builder
        var finishedTimer: BTTimer!
        Self.onBuildRequest = {  _, timer, _ in
            finishedTimer = timer
        }

        // Uploader
        let requestExpectation = self.expectation(description: "Request sent")
        Self.onSendRequest = { _ in
            requestExpectation.fulfill()
        }

        // BlueTriangleConfiguration
        let configuration = BlueTriangleConfiguration()
        Mock.configureBlueTriangle(configuration: configuration)
        configuration.requestBuilder = Self.requestBuilder

        // Configure Blue Triangle
        BlueTriangle.reconfigure(
            configuration: configuration,
            logger: Self.logger,
            uploader: Self.uploader,
            timerFactory: timerFactory,
            shouldCaptureRequests: false,
            requestCollector: nil
        )

        // ViewController
        let imageSize: CGSize = .init(width: 150, height: 150)
        let delayStragegy: DelayGenerator.Strategy = .random((mean: 1, variation: 0.5))
        let networkClient: NetworkClientMock = .makeClient(delayStrategy: delayStragegy,
                                                           imageSize: imageSize)
        let viewController = CollectionViewController(networkClient: networkClient)
        viewController.viewDidLoad()

        waitForExpectations(timeout: 10.0)

        XCTAssertNotNil(finishedTimer)
    }
}
#endif
