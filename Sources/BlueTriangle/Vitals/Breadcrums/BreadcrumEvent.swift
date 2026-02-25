//
//  BreadcrumEvent.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//

import Foundation

protocol BreadcrumEvent: Encodable {
    var timestamp: Millisecond { get }
    var type: BreadcrumType { get }
    var data: [BreadcrumKeys: String] { get }
}

extension BreadcrumEvent {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BreadcrumKeys.self)
        
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type.rawValue, forKey: .type)
        
        var dataContainer = container.nestedContainer(keyedBy: BreadcrumKeys.self, forKey: .data)
        
        for (key, value) in data {
            try dataContainer.encode(value, forKey: key)
        }
    }
}

struct AppLifecycleEvent: BreadcrumEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    
    var type: BreadcrumType { .appLifecycle }
    
    var data: [BreadcrumKeys : String] {
        [.event: event]
    }
}

struct UILifecycleEvent: BreadcrumEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    let className: String
    
    var type: BreadcrumType { .uiLifecycle }
    
    var data: [BreadcrumKeys : String] {
        [
            .event: event,
            .className: className
        ]
    }
}

struct NetworkRequestEvent: BreadcrumEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let url: String
    let statusCode: Int
    
    var type: BreadcrumType { .networkRequest }
    
    var data: [BreadcrumKeys : String] {
        [
            .url: url,
            .statusCode: String(statusCode)
        ]
    }
}

enum BreadcrumType: String, Codable {
    case appLifecycle = "app.lifecycle"
    case uiLifecycle = "ui.lifecycle"
    case networkRequest = "network.request"
}

enum BreadcrumKeys: String, CodingKey, Codable {
    case data
    case timestamp
    case type
    case event
    case className
    case url
    case statusCode
}
