//
//  Session.swift
//
//  Created by Mathew Gacy on 10/12/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct Session: Equatable {
    let wcd = 1
    let eventType = 9
    let navigationType = 9
    let osInfo = Device.os
    let appVersion = Device.bvzn

    /// Blue Triangle Technologies-assigned site ID.
    var siteID: String

    /// Global User ID.
    var globalUserID: Identifier

    /// Session ID.
    var sessionID: Identifier

    /// Boolean value indicating whether user is a returning visitor.
    var isReturningVisitor: Bool

    /// A/B testing identifier.
    var abTestID: String

    /// Legacy campaign name.
    var campaign: String?

    /// Campaign medium.
    var campaignMedium: String

    /// Campaign name.
    var campaignName: String

    /// Campaign source.
    var campaignSource: String

    /// Data center.
    var dataCenter: String

    /// Traffic segment.
    var trafficSegmentName: String

    /// Custom metrics.
    var metrics: [String: AnyCodable]?
}
