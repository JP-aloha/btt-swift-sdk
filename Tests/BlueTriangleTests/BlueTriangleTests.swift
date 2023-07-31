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
                           encode: { try requestEncoder.encode($0).base64EncodedData() })
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
        let requestString = String(data: base64Decoded, encoding: .utf8)
        let expectedString = Mock.makeTimerRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion,
            sdkVersion: Version.number)

        XCTAssertEqual(requestString, expectedString)
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
        let requestString = String(data: base64Decoded, encoding: .utf8)
        let expectedString = Mock.makeTimerRequestJSON(
            appVersion: Bundle.main.releaseVersionNumber ?? "0.0",
            os: Device.os,
            osVersion: Device.osVersion,
            sdkVersion: Version.number)

        XCTAssertEqual(requestString, expectedString)
    }
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
                requestBuilder: .makeBuilder { Mock.session },
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
        await waitForExpectations(timeout: 1.0)

        requestExpectation = self.expectation(description: "Request sent")

        timer.end()

        _ = BlueTriangle.startTimer(page: Page(pageName: "Another_Page"))
        await waitForExpectations(timeout: 1.0)

        let capturedRequestString = String(data: Data(base64Encoded: capturedRequest.body!)!, encoding: .utf8)
        XCTAssertEqual(capturedRequestString, Mock.capturedRequestJSON)
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
        print(performanceMonitor.measurements)

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
