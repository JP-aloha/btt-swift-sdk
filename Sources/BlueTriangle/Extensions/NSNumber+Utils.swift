//
//  NSNumber+Utils.swift
//
//  Created by Mathew Gacy on 2/6/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

extension NSNumber {
    enum NumberType: Equatable {
        case bool(Bool)
        case int(Int)
        case double(Double)
        case unknown
    }

    func numberType() -> NumberType {
        switch CFNumberGetType(self) {
        case .charType:
            return .bool(self.boolValue)
        case .sInt8Type, .sInt16Type, .sInt32Type, .sInt64Type, .shortType, .intType, .longType, .longLongType, .cfIndexType, .nsIntegerType:
            return .int(self.intValue)
        case .float32Type, .float64Type, .floatType, .doubleType, .cgFloatType:
            return .double(self.doubleValue)
        @unknown default:
            return .unknown
        }
    }
}
