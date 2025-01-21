//
//  CaptureTimerManagerTests.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

class CaptureTimerManagerTests: XCTestCase {

    func testStartFromInactive() throws {
        let configuration = NetworkCaptureConfiguration(
            spanCount: 2,
            initialSpanDuration: 0.5,
            subsequentSpanDuration: 0.2)
        let manager = CaptureTimerManager(configuration: configuration)

        let expectedFireCount = configuration.spanCount
        let fireExpectation = expectation(description: "Timer fired twice.")

        let additionalFireExpectation = expectation(description: "Fire count exceeded spanCount.")
        additionalFireExpectation.isInverted = true

        var fireCount: Int = 0
        manager.handler = {
            fireCount += 1
            if fireCount == expectedFireCount {
                fireExpectation.fulfill()
            } else if fireCount > expectedFireCount {
                additionalFireExpectation.fulfill()
            }
        }
        manager.start()

        waitForExpectations(timeout: 10)
        XCTAssertEqual(manager.state, .inactive)
    }

    func testStartFromActive() throws {
        var queue: DispatchQueue {
            DispatchQueue(label: "com.bluetriangle.testActive",
                          qos: .userInitiated,
                          autoreleaseFrequency: .workItem)
        }
        let configuration = NetworkCaptureConfiguration(
            spanCount: 2,
            initialSpanDuration: 1.0,
            subsequentSpanDuration: 0.3)

        let manager = CaptureTimerManager(configuration: configuration)

        let excessiveFireExpectation = expectation(description: "Fire count exceeded spanCount.")
        excessiveFireExpectation.isInverted = true

        var fireCount: Int = 0
        manager.handler = {
            fireCount += 1
            if fireCount > 3 {
                excessiveFireExpectation.fulfill()
            }
        }

        manager.start()

        queue.asyncAfter(deadline: .now() + 0.1) {
            guard case let .active(_, span) = manager.state else {
                XCTFail("Unexpected manager state")
                return
            }
            XCTAssertEqual(span, 1)
            XCTAssertEqual(fireCount, 0)
            manager.start()
        }

        waitForExpectations(timeout: 50.0)
        XCTAssertEqual(fireCount, 2)
    }

    func testCancelFromActive() throws {
        var queue: DispatchQueue {
            DispatchQueue(label: "com.bluetriangle.testCancel",
                          qos: .userInitiated,
                          autoreleaseFrequency: .workItem)
        }
        let configuration = NetworkCaptureConfiguration(
            spanCount: 10,
            initialSpanDuration: 0.5,
            subsequentSpanDuration: 0.2)

        let manager = CaptureTimerManager(configuration: configuration)

        let fireExpectation = expectation(description: "Timer fired.")
        fireExpectation.isInverted = true
        manager.handler = {
            fireExpectation.fulfill()
        }

        manager.start()

        queue.asyncAfter(deadline: .now() + 0.1) {
            guard case let .active(_, span) = manager.state else {
                XCTFail("Unexpected manager state")
                return
            }
            XCTAssertEqual(span, 1)
            manager.cancel()
            XCTAssertEqual(manager.state, .inactive)
        }

        waitForExpectations(timeout: 10)
        XCTAssertEqual(manager.state, .inactive)
    }
}
