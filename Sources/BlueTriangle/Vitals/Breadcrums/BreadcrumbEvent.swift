//
//  BreadcrumEvent.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//

import Foundation

protocol BreadcrumbEvent: Encodable {
    var timestamp: Millisecond { get }
    var type: BreadcrumbType { get }
    var data: [BreadcrumbKeys: String] { get }
}

extension BreadcrumbEvent {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: BreadcrumbKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type.rawValue, forKey: .type)
        var dataContainer = container.nestedContainer(keyedBy: BreadcrumbKeys.self, forKey: .data)
        for (key, value) in data {
            try dataContainer.encode(value, forKey: key)
        }
    }
}

struct AppLifecycleEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    
    var type: BreadcrumbType { .appLifecycle }
    
    var data: [BreadcrumbKeys : String] {
        [.event: event]
    }
}

struct UILifecycleEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    let className: String
    
    var type: BreadcrumbType { .uiLifecycle }
    
    var data: [BreadcrumbKeys : String] {
        [
            .event: event,
            .className: className
        ]
    }
}

struct NetworkRequestEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let url: String
    let statusCode: String
    
    var type: BreadcrumbType { .networkRequest }
    
    var data: [BreadcrumbKeys : String] {
        [
            .url: url,
            .statusCode: statusCode
        ]
    }
}

struct NetworkStateEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    var type: BreadcrumbType { .networkState }
    var data: [BreadcrumbKeys : String] {
        [
            .state: BlueTriangle.networkStateMonitor?.state.value?.description.lowercased() ?? ""
        ]
    }
}

enum BreadcrumbType: String, Codable {
    case appLifecycle = "app.lifecycle"
    case uiLifecycle = "ui.lifecycle"
    case networkRequest = "network.request"
    case networkState = "network.state"
}

enum BreadcrumbKeys: String, CodingKey, Codable {
    case data
    case timestamp
    case type
    case event
    case className
    case url
    case statusCode
    case state
}
