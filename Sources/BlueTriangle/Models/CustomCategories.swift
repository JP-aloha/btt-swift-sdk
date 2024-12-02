//
//  CustomCategories.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// Custom textual data that is collected from the page, aggregated, and ultimately
/// appears in the list of filter options in the Blue Triangle portal.
@objcMembers
@available(*, deprecated, message: "Use BlueTriangle 'setCustomVariable(_ name:, value:)' method instead.")
final public class CustomCategories: NSObject {
    /// Custom category for data collection use.
    public var cv6: String?

    /// Custom category for data collection use.
    public var cv7: String?

    /// Custom category for data collection use.
    public var cv8: String?

    /// Custom category for data collection use.
    public var cv9: String?

    /// Custom category for data collection use.
    public var cv10: String?

    /// Creates custom categories describing a user interaction.
    /// - Parameters:
    ///   - cv6: Custom category for data collection use.
    ///   - cv7: Custom category for data collection use.
    ///   - cv8: Custom category for data collection use.
    ///   - cv9: Custom category for data collection use.
    ///   - cv10: Custom category for data collection use.
    public init(
        cv6: String?,
        cv7: String?,
        cv8: String?,
        cv9: String?,
        cv10: String?
    ) {
        self.cv6 = cv6
        self.cv7 = cv7
        self.cv8 = cv8
        self.cv9 = cv9
        self.cv10 = cv10
    }
}
