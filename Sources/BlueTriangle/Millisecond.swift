//
//  Millisecond.swift
//
//  Created by Mathew Gacy on 10/11/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

/// The milliseconds between an event and 00:00:00 UTC on 1 January 1970.
public typealias Millisecond = Int64

extension Millisecond {
    static var minute: Self {
        60_000
    }

    static var hour: Self {
        .minute * 60
    }

    static var day: Self {
        .hour * 24
    }

    static var sessionTimeout: Self {
        minute * Self(Constants.sessionTimeoutInMinutes)
    }

    static var userTimeout: Self {
        day * Self(Constants.userSessionTimeoutInDays)
    }
}

extension Int {
    var asTimeInterval: TimeInterval {
        TimeInterval(self) / 1000.0
    }
}
