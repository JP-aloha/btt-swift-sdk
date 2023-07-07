//
//  Mock.swift
//
//  Created by Mathew Gacy on 10/15/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import Combine
import Foundation
import XCTest

// swiftlint:disable line_length

// MARK: - Response
enum Mock {
    typealias Response = (data: Data, response: HTTPURLResponse)

    struct TestError: Error {}

    static let errorJSON = """
          {
            "error": "someError"
          }
          """.data(using: .utf8)!

    static let successJSON = """
          {
            "foo": "bar"
          }
          """.data(using: .utf8)!

    static func makeHTTPResponse(
        url: URL = "https://example.com",
        statusCode: Int = 200,
        headerFields: [String: String]? = nil
    ) -> HTTPURLResponse {
        HTTPURLResponse(url: url,
                        statusCode: statusCode,
                        httpVersion: nil,
                        headerFields: headerFields)!
    }

    static func makeCapturedResponse(expectedContentLength: Int = 100) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: Mock.capturedRequestURLString)!,
            mimeType: nil,
            expectedContentLength: expectedContentLength,
            textEncodingName: nil)
    }

    static var successResponse = HTTPResponse<Data>(
        value: successJSON,
        response: makeHTTPResponse(statusCode: 200))

    static var errorResponse = HTTPResponse<Data>(
        value: errorJSON,
        response: makeHTTPResponse(statusCode: 400))

    static var urlSuccessResponse = Response(
        data: successJSON,
        response: makeHTTPResponse(statusCode: 200))

    static var urlErrorResponse = Response(
        data: errorJSON,
        response: makeHTTPResponse(statusCode: 400))

}

// MARK: - Configuration
extension Mock {
    static var uploaderQueue: DispatchQueue {
        DispatchQueue(label: "com.bluetriangle.test",
                      qos: .userInitiated,
                      autoreleaseFrequency: .workItem)
    }

    static func configureBlueTriangle(configuration config: BlueTriangleConfiguration) {
        config.siteID = session.siteID
        config.globalUserID = session.globalUserID
        config.sessionID = session.sessionID
        config.isReturningVisitor = session.isReturningVisitor
        config.abTestID = session.abTestID
        config.campaignMedium = session.campaignMedium
        config.campaignName = session.campaignName
        config.campaignSource = session.campaignSource
        config.dataCenter = session.dataCenter
        config.trafficSegmentName = session.trafficSegmentName
    }

    static func makeRequestBuilder(
        onBuild: @escaping (Session, BTTimer, PurchaseConfirmation?) -> Void = { _, _, _ in }
    ) -> TimerRequestBuilder {
        TimerRequestBuilder { session, timer, purchaseConfirmation in
            onBuild(session, timer, purchaseConfirmation)
            return Request(method: .post, url: "https://example.com")
        }
    }

    static var retryConfiguration = Uploader.RetryConfiguration<DispatchQueue>(maxRetry: 2,
                                                                               initialDelay: 0.1,
                                                                               delayMultiplier: 0.1,
                                                                               shouldRetry: nil)

    static func makeUploaderConfiguration(
        queue: DispatchQueue,
        onSend: @escaping (Request) -> Void = { _ in }
    ) -> Uploader.Configuration {
        Uploader.Configuration(
            queue: queue,
            networking: { request in
                Deferred {
                    Future { promise in
                        onSend(request)
                        promise(.success(Mock.successResponse))
                    }
                }.eraseToAnyPublisher()
            },
            retryConfiguration: retryConfiguration)
    }

    static func makeTimerConfiguration(
        intervalProvider: @escaping () -> TimeInterval
    ) -> BTTimer.Configuration {
        BTTimer.Configuration(
            timeIntervalProvider: intervalProvider
        )
    }

    static func makePerformanceMonitor(timerInterval: TimeInterval) -> PerformanceMonitoring {
        PerformanceMonitorMock()
    }

    static func makeRequestCollectorConfiguration(
        timerManagingProvider: @escaping (NetworkCaptureConfiguration) -> CaptureTimerManaging = { _ in CaptureTimerManagerMock() }
    ) -> CapturedRequestCollector.Configuration {
        .init(timerManagingProvider: timerManagingProvider)
    }
}

// MARK: - Models
extension Mock {
    static var customCategories = CustomCategories(
        cv6: "CV6",
        cv7: "CV7",
        cv8: "CV8",
        cv9: "CV9",
        cv10: "CV10")

    static var customNumbers = CustomNumbers(
        cn1: 1.11,
        cn2: 2.22,
        cn3: 3.33,
        cn4: 4.44,
        cn5: 5.55,
        cn6: 6.66,
        cn7: 7.77,
        cn8: 8.88,
        cn9: 9.99,
        cn10: 10.10,
        cn11: 11.11,
        cn12: 12.12,
        cn13: 13.13,
        cn14: 14.14,
        cn15: 15.15,
        cn16: 16.16,
        cn17: 17.17,
        cn18: 18.18,
        cn19: 19.19,
        cn20: 20.20)

    static var customVariables = CustomVariables(
        cv1: "CV1",
        cv2: "CV2",
        cv3: "CV3",
        cv4: "CV4",
        cv5: "CV5",
        cv11: "CV11",
        cv12: "CV12",
        cv13: "CV13",
        cv14: "CV14",
        cv15: "CV15")

    static var globalUserID: Identifier = 888_888_888_888_888_888

    static var sessionID: Identifier = 999_999_999_999_999_999

    static var page = Page(
        pageName: "MY_PAGE_NAME",
        brandValue: 0.51,
        pageType: "MY_PAGE_TYPE",
        referringURL: "MY_REFERRING_URL",
        url: "MY_URL",
        customVariables: Mock.customVariables,
        customCategories: Mock.customCategories,
        customNumbers: Mock.customNumbers)

    static var purchaseConfirmation = PurchaseConfirmation(
        cartValue: 99.99,
        orderNumber: "MY_ORDER_NUMBER")

    static var header: Request.Headers = [
        "Host": "example.com",
        "Content-Type": "application/x-www-form-urlencoded",
        "Connection": "keep-alive",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept-Encoding": "gzip, deflate, br"
    ]

    static var request = Request(
        method: .post,
        url: "http://example.com",
        headers: Mock.header,
        body: Mock.successJSON)

    static var session = Session(
        siteID: "MY_SITE_ID",
        globalUserID: Mock.globalUserID,
        sessionID: Mock.sessionID,
        isReturningVisitor: true,
        abTestID: "MY_AB_TEST_ID",
        campaignMedium: "MY_CAMPAIGN_MEDIUM",
        campaignName: "MY_CAMPAIGN_NAME",
        campaignSource: "MY_CAMPAIGN_SOURCE",
        dataCenter: "MY_DATA_CENTER",
        trafficSegmentName: "MY_SEGMENT_NAME")

    static var timerInterval = PageTimeInterval(
        startTime: 2000,
        interactiveTime: 3000,
        pageTime: 1000)

    static var timerRequest = TimerRequest(
        session: Mock.session,
        page: Mock.page,
        timer: Mock.timerInterval,
        purchaseConfirmation: Mock.purchaseConfirmation,
        performanceReport: nil)

    static var performanceReport = PerformanceReport(
        minCPU: 0.0,
        maxCPU: 0.0,
        avgCPU: 0.0,
        minMemory: 0,
        maxMemory: 0,
        avgMemory: 0)

    static let capturedRequestURLString = "https://d33wubrfki0l68.cloudfront.net/f50c058607f066d0231c1fe6753eac79f17ea447/e6748/static/logo-cw.f6eaf6dc.png"

    static func makeCapturedRequest(
        startTime: Millisecond = 100,
        endTime: Millisecond = 200
    ) -> CapturedRequest {
        CapturedRequest(
            domain: "cloudfront.net",
            host: "d33wubrfki0l68",
            url: capturedRequestURLString,
            file: "logo-cw.f6eaf6dc.png",
            statusCode: "200",
            startTime: startTime,
            endTime: endTime,
            duration: endTime - startTime,
            initiatorType: .image,
            decodedBodySize: 100,
            encodedBodySize: 0)
    }
}

// MARK: - Request
extension Mock {
    static var capturedRequestJSON = "[{\"rE\":3000,\"h\":\"example\",\"sT\":2000,\"i\":\"other\",\"ez\":0,\"URL\":\"https:\\/\\/example.com\\/foo.json\",\"dz\":-1,\"d\":1000,\"e\":\"resource\",\"f\":\"foo.json\",\"rCd\":\"200\",\"dmn\":\"example.com\"}]"

    static func makeTimerRequestJSON(appVersion: String, os: String, osVersion: String, sdkVersion: String) -> String {
        """
        {\"AB\":\"MY_AB_TEST_ID\",\"avgCPU\":50,\"avgMemory\":50000000,\"browser\":\"Native App\",\"bv\":0.51,\"bvzn\":\"Native App-\(appVersion)-\(os) \(osVersion)\",\"campaign\":null,\"CmpM\":\"MY_CAMPAIGN_MEDIUM\",\"CmpN\":\"MY_CAMPAIGN_NAME\",\"CmpS\":\"MY_CAMPAIGN_SOURCE\",\"CN1\":1.1100000000000001,\"CN2\":2.2200000000000002,\"CN3\":3.3300000000000001,\"CN4\":4.4400000000000004,\"CN5\":5.5499999999999998,\"CN6\":6.6600000000000001,\"CN7\":7.7699999999999996,\"CN8\":8.8800000000000008,\"CN9\":9.9900000000000002,\"CN10\":10.1,\"CN11\":11.109999999999999,\"CN12\":12.119999999999999,\"CN13\":13.130000000000001,\"CN14\":14.140000000000001,\"CN15\":15.15,\"CN16\":16.16,\"CN17\":17.170000000000002,\"CN18\":18.18,\"CN19\":19.190000000000001,\"CN20\":20.199999999999999,\"CV1\":\"CV1\",\"CV2\":\"CV2\",\"CV3\":\"CV3\",\"CV4\":\"CV4\",\"CV5\":\"CV5\",\"CV6\":\"CV6\",\"CV7\":\"CV7\",\"CV8\":\"CV8\",\"CV9\":\"CV9\",\"CV10\":\"CV10\",\"CV11\":\"CV11\",\"CV12\":\"CV12\",\"CV13\":\"CV13\",\"CV14\":\"CV14\",\"CV15\":\"CV15\",\"DCTR\":\"MY_DATA_CENTER\",\"device\":\"Mobile\",\"domInteractive\":1000000,\"EUOS\":\"\(os)\",\"eventType\":9,\"gID\":888888888888888888,\"maxCPU\":100,\"maxMemory\":100000000,\"minCPU\":1,\"minMemory\":10000000,\"NAflg\":1,\"navigationType\":9,\"nst\":0,\"os\":\"iOS\",\"pageName\":\"MY_PAGE_NAME\",\"pageType\":\"MY_PAGE_TYPE\",\"pgTm\":2000000,\"RefURL\":\"MY_REFERRING_URL\",\"RV\":1,\"sID\":999999999999999999,\"siteID\":\"MY_SITE_ID\",\"thisURL\":\"MY_URL\",\"txnName\":\"MY_SEGMENT_NAME\",\"unloadEventStart\":0,\"VER\":\"\(sdkVersion)\",\"wcd\":1}
        """
    }
}
