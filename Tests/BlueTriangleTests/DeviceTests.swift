//
//  DeviceTests.swift
//
//  Created by Mathew Gacy on 7/18/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import XCTest
@testable import BlueTriangle

final class DeviceTests: XCTestCase {
    func testOSInfo() {
        let os = Device.os
        let osVersion = Device.osVersion
        let name = Device.name

        #if os(iOS)
        XCTAssertEqual(os, "iOS")
        #elseif os(tvOS)
        XCTAssertEqual(os, "tvOS")
        #elseif os(watchOS)
        XCTAssertEqual(os, "watchOS")
        #elseif os(macOS)
        XCTAssertEqual(os, "macOS")
        #endif

        XCTAssertFalse(osVersion.isEmpty)
        XCTAssertFalse(name.isEmpty)
    }
}
