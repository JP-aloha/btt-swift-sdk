//
//  NativeAppProperties.swift
//  
//
//  Created by JP on 14/06/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

enum ViewType : String, Encodable, Decodable {
    case UIKit
    case SwiftUI
}

struct NativeAppProperties: Codable, Equatable {
    let fullTime: Millisecond
    let loadTime: Millisecond
    let maxMainThreadUsage: Millisecond
    let viewType: ViewType
    
}

extension NativeAppProperties {
    static let empty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        maxMainThreadUsage: 0,
        viewType: .UIKit)
}


struct ECV: Codable, Equatable {
    let minCPU: Float
    let maxCPU: Float
    let avgCPU: Float
    let minMemory: UInt64
    let maxMemory: UInt64
    let avgMemory: UInt64
}

extension ECV {
    static let empty: Self = .init(
        minCPU: 0.0,
        maxCPU: 0.0,
        avgCPU: 0.0,
        minMemory: 0,
        maxMemory: 0,
        avgMemory: 0)
}

