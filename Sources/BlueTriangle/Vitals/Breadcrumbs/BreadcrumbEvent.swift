//
//  BreadcrumEvent.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//

import Foundation

protocol BreadcrumbEvent: Codable {
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

enum BreadcrumbType: String, Codable {
    case appLifecycle = "app.lifecycle"
    case uiLifecycle = "ui.lifecycle"
    case networkRequest = "network.request"
    case networkState = "network.state"
    case appInstall = "app.install"
    case appUpdate = "app.update"
    case userEvent = "user.event"
    case systemEvent = "system.event"
}

enum BreadcrumbKeys: String, CodingKey, Codable {
    case data
    case timestamp
    case type
    case eventType
    case event
    case className
    case url
    case statusCode
    case state
    case from
    case to
    case version
    case action
    case targetClass
    case targetId
    case x
    case y

}
