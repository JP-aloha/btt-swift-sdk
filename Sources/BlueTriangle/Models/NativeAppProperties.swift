//
//  NativeAppProperties.swift
//  
//
//  Created by Ashok Singh on 14/06/23.
//

import Foundation

enum ViewType : String, Encodable, Decodable {
    case UIKit
    case SwiftUI
}

struct NativeAppProperties: Codable, Equatable {
    let fullTime: Millisecond
    let loadTime: Millisecond
    let maxMainThreadUses: Millisecond
    let viewType: ViewType
}

extension NativeAppProperties {
    static let empty: Self = .init(
        fullTime: 0,
        loadTime: 0,
        maxMainThreadUses: 0,
        viewType: .UIKit)
}
