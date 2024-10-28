//
//  UtilityTests.swift
//
//  Created by Mathew Gacy on 2/6/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

@testable import BlueTriangle
import XCTest

final class UtilityTests: XCTestCase {}

// MARK: - NSNumber+Utils
extension UtilityTests {
    func testBoolIdentification() {
        let bool: Bool = true
        let nsNumber = NSNumber(value: bool)
        XCTAssertEqual(nsNumber.numberType(), .bool(bool))
    }

    func testDoubleIdentification() {
        let double: Double = 9.99
        let nsNumber = NSNumber(value: double)
        XCTAssertEqual(nsNumber.numberType(), .double(double))
    }

    func testFloatIdentification() {
        let float: Float = 11.11
        let nsNumber = NSNumber(value: float)
        XCTAssertEqual(nsNumber.numberType(), .double(Double(float)))
    }

    func testIntIdentification() {
        let int: Int = 9
        let nsNumber = NSNumber(value: int)
        XCTAssertEqual(nsNumber.numberType(), .int(int))
    }

    func testInt64Identification() {
        let int64: Int64 = .max
        let nsNumber = NSNumber(value: int64)
        XCTAssertEqual(nsNumber.numberType(), .int(Int(int64)))
    }
}
