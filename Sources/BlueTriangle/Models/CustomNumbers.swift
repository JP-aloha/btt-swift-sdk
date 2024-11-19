//
//  CustomNumbers.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// Custom numeric data that is collected from the page, aggregated, and ultimately
/// appears on your trend graphs in the Blue Triangle portal.
@objcMembers
@available(*, deprecated, message: "Use BlueTriangle 'setCustomVariable(_ name:, value:)' method instead.")
final public class CustomNumbers: NSObject {
    /// Custom number for data collection use.
    public var cn1: Double

    /// Custom number for data collection use.
    public var cn2: Double

    /// Custom number for data collection use.
    public var cn3: Double

    /// Custom number for data collection use.
    public var cn4: Double

    /// Custom number for data collection use.
    public var cn5: Double

    /// Custom number for data collection use.
    public var cn6: Double

    /// Custom number for data collection use.
    public var cn7: Double

    /// Custom number for data collection use.
    public var cn8: Double

    /// Custom number for data collection use.
    public var cn9: Double

    /// Custom number for data collection use.
    public var cn10: Double

    /// Custom number for data collection use.
    public var cn11: Double

    /// Custom number for data collection use.
    public var cn12: Double

    /// Custom number for data collection use.
    public var cn13: Double

    /// Custom number for data collection use.
    public var cn14: Double

    /// Custom number for data collection use.
    public var cn15: Double

    /// Custom number for data collection use.
    public var cn16: Double

    /// Custom number for data collection use.
    public var cn17: Double

    /// Custom number for data collection use.
    public var cn18: Double

    /// Custom number for data collection use.
    public var cn19: Double

    /// Custom number for data collection use.
    public var cn20: Double

    /// Creates custom numbers for describing a user interaction.
    /// - Parameters:
    ///   - cn1: Custom number for data collection use.
    ///   - cn2: Custom number for data collection use.
    ///   - cn3: Custom number for data collection use.
    ///   - cn4: Custom number for data collection use.
    ///   - cn5: Custom number for data collection use.
    ///   - cn6: Custom number for data collection use.
    ///   - cn7: Custom number for data collection use.
    ///   - cn8: Custom number for data collection use.
    ///   - cn9: Custom number for data collection use.
    ///   - cn10: Custom number for data collection use.
    ///   - cn11: Custom number for data collection use.
    ///   - cn12: Custom number for data collection use.
    ///   - cn13: Custom number for data collection use.
    ///   - cn14: Custom number for data collection use.
    ///   - cn15: Custom number for data collection use.
    ///   - cn16: Custom number for data collection use.
    ///   - cn17: Custom number for data collection use.
    ///   - cn18: Custom number for data collection use.
    ///   - cn19: Custom number for data collection use.
    ///   - cn20: Custom number for data collection use.
    public init(
        cn1: Double = 0.0,
        cn2: Double = 0.0,
        cn3: Double = 0.0,
        cn4: Double = 0.0,
        cn5: Double = 0.0,
        cn6: Double = 0.0,
        cn7: Double = 0.0,
        cn8: Double = 0.0,
        cn9: Double = 0.0,
        cn10: Double = 0.0,
        cn11: Double = 0.0,
        cn12: Double = 0.0,
        cn13: Double = 0.0,
        cn14: Double = 0.0,
        cn15: Double = 0.0,
        cn16: Double = 0.0,
        cn17: Double = 0.0,
        cn18: Double = 0.0,
        cn19: Double = 0.0,
        cn20: Double = 0.0
    ) {
        self.cn1 = cn1
        self.cn2 = cn2
        self.cn3 = cn3
        self.cn4 = cn4
        self.cn5 = cn5
        self.cn6 = cn6
        self.cn7 = cn7
        self.cn8 = cn8
        self.cn9 = cn9
        self.cn10 = cn10
        self.cn11 = cn11
        self.cn12 = cn12
        self.cn13 = cn13
        self.cn14 = cn14
        self.cn15 = cn15
        self.cn16 = cn16
        self.cn17 = cn17
        self.cn18 = cn18
        self.cn19 = cn19
        self.cn20 = cn20
    }
}
