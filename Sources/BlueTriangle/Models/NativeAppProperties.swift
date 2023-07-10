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
