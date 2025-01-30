//
//  InternalTimer.swift
//
//  Created by Mathew Gacy on 2/20/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// An time that measures the duration of app events like network requuests.
public struct InternalTimer {

    /// Describes the state of a timer.
    public enum State {
        /// Timer has not yet been started.
        case initial
        /// Timer has been started.
        case started
        /// Timer has been ended.
        case ended
    }

    private enum Action {
        case start
        case end
    }

    private let timeIntervalProvider: () -> TimeInterval
    private let logger: Logging

    /// The state of the timer.
    public private(set) var state: State = .initial

    /// The epoch time interval at which the timer was started.
    ///
    /// The default value is `0.0`.
    public private(set) var startTime: TimeInterval = 0.0

    /// The epoch time interval at which the timer was ended.
    ///
    /// The default value is `0.0`.
    public private(set) var endTime: TimeInterval = 0.0
    
    private let enableAllTracking = BlueTriangle.enableAllTracking

    init(logger: Logging,
         intervalProvider: @escaping () -> TimeInterval = { Date().timeIntervalSince1970 }
    ) {
        self.logger = logger
        self.timeIntervalProvider = intervalProvider
    }

    mutating func start() {
        guard enableAllTracking else {
            return
        }
        
        handle(.start)
    }

    /// Ends the timer.
    public mutating func end() {
        guard enableAllTracking else {
            return
        }
        
        handle(.end)
    }

    private mutating func handle(_ action: Action) {
        switch (state, action) {
        case (.initial, .start):
            startTime = timeIntervalProvider()
            state = .started
        case (.started, .end):
            endTime = timeIntervalProvider()
            state = .ended
        case (.initial, .end):
            logger.error("Cannot end timer before it is started.")
        case (.started, .start):
            logger.error("Start time already set.")
        case (.ended, .start), (.ended, .end):
            logger.error("Timer already ended.")
        }
    }
}

// MARK: - CustomStringConvertible
extension InternalTimer.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .initial: return ".initial"
        case .started: return ".started"
        case .ended: return ".ended"
        }
    }
}

extension InternalTimer: CustomStringConvertible {
    public var description: String {
        "InternalTimer(state: \(state), startTime: \(startTime), endTime: \(endTime))"
    }
}

// MARK: - Supporting Types
extension InternalTimer {
    struct Configuration {
        let timeIntervalProvider: () -> TimeInterval

        func makeTimerFactory(logger: Logging) -> () -> InternalTimer {
            { InternalTimer(logger: logger, intervalProvider: timeIntervalProvider) }
        }

        static let live = Self(
            timeIntervalProvider: { Date().timeIntervalSince1970 }
        )
    }
}
