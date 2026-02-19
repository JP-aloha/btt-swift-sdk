//
//  CapturedRequestBuilder.swift
//
//  Created by Mathew Gacy on 2/22/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct CapturedRequestBuilder {
    let build: (Millisecond, Page, [CapturedRequest]) throws -> Request

    // swiftlint:disable:next function_parameter_count
    static func makeParameters(
        siteID: String,
        sessionID: String,
        trafficSegment: String,
        isNewUser: Bool,
        pageType: String,
        pageName: String,
        startTime: Millisecond
    ) -> Request.Parameters {
        [
            "siteID": siteID,
            "nStart": String(startTime),
            "pageName": pageName,
            "txnName": trafficSegment,
            "sessionID": String(sessionID),
            "WCDtt": "c",
            "NVSTR": isNewUser.smallIntString,
            "pageType": pageType,
            "os": Constants.os,
            "browser": Constants.browser,
            "browserVersion": Device.bvzn,
            "device": Constants.device
        ]
    }

    static func makeBuilder(sessionProvider: @escaping () -> Session?) -> Self {
        .init { startTime, page, requests in
            var parameters : [String: String]?
            if let session = sessionProvider() {
                 parameters = CapturedRequestBuilder.makeParameters(
                    siteID: session.siteID,
                    sessionID: String(session.sessionID),
                    trafficSegment: !page.trafficSegment.isEmpty ? page.trafficSegment : session.trafficSegmentName,
                    isNewUser: !session.isReturningVisitor,
                    pageType: !page.pageType.isEmpty ? page.pageType : session.pageType,
                    pageName: page.pageName,
                    startTime: startTime
                )
            }

            return try Request(method: .post,
                               url: Constants.capturedRequestEndpoint,
                               parameters: parameters,
                               model: requests)
        }
    }
}
