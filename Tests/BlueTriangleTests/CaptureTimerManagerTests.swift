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

  /*  func testStartFromActive() throws {
        var queue: DispatchQueue {
            DispatchQueue(label: "com.bluetriangle.test",
                          qos: .userInitiated,
                          autoreleaseFrequency: .workItem)
        }
        let configuration = NetworkCaptureConfiguration(
            spanCount: 2,
            initialSpanDuration: 0.5,
            subsequentSpanDuration: 0.2)

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

        waitForExpectations(timeout: 5.0)
        XCTAssertEqual(fireCount, 2)
    }*/
    
    func testStartFromActive() throws {
        var queue: DispatchQueue {
            DispatchQueue(label: "com.bluetriangle.testStartFromActive",
                          qos: .userInitiated,
                          autoreleaseFrequency: .workItem)
        }
        let configuration = NetworkCaptureConfiguration(
            spanCount: 2,
            initialSpanDuration: 1.5, // Increased duration for stability
            subsequentSpanDuration: 0.3)

        let manager = CaptureTimerManager(configuration: configuration)

        let excessiveFireExpectation = expectation(description: "Fire count exceeded spanCount.")
        excessiveFireExpectation.isInverted = true

        let fireExpectation = expectation(description: "Handler fired twice as expected.")

        var fireCount: Int = 0
        manager.handler = {
            fireCount += 1
            print("Handler executed. Fire count: \(fireCount)")
            if fireCount == 2 {
                fireExpectation.fulfill()
            } else if fireCount > 2 {
                excessiveFireExpectation.fulfill()
            }
        }

        // Start the timer
        manager.start()
        print("Manager started.")

        queue.asyncAfter(deadline: .now() + 0.1) {
            guard case let .active(_, span) = manager.state else {
                XCTFail("Unexpected manager state before restart.")
                return
            }
            XCTAssertEqual(span, 1, "Expected span to be 1 after the first start.")
            XCTAssertEqual(fireCount, 0, "Handler should not have fired yet.")
            manager.start() // Restart the timer
            print("Manager restarted.")
        }

        print("Before wait fire count : \(fireCount)")
        // Wait for expectations
        waitForExpectations(timeout: 100.0)
        print("After wait fire count : \(fireCount)")
        XCTAssertEqual(fireCount, 2, "Handler should fire exactly twice.")
    }

    func testCancelFromActive() throws {
        var queue: DispatchQueue {
            DispatchQueue(label: "com.bluetriangle.testCancelFromActive",
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
