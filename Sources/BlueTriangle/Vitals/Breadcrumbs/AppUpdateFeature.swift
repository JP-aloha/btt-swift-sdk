//
//  AppUpdateFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 27/02/26.
//

import Foundation

final class AppUpdateFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .appUpdate
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct AppUpdateEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    let fromVersion: String
    let toVersion: String
    var type: BreadcrumbType { .appUpdate }
    
    var data: [BreadcrumbKeys : String] {
        [
            .event: event,
            .fromVersion: fromVersion,
            .toVersion: toVersion
        ]
    }
}
