//
//  ResponsivenessTrackerBuilder.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

struct ResponsivenessTrackerBuilder {
    let builder: () -> ResponsivenessTracking?

    static let live: Self = ResponsivenessTrackerBuilder {
        #if os(iOS) || os(tvOS)
        return ResponsivenessTracker()
        #else
        return nil
        #endif
    }
}
