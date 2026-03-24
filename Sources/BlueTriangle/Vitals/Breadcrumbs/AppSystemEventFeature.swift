//
//  SystemEvent.swift
//  blue-triangle
//
//  Created by Ashok Singh on 11/03/26.
//

import Foundation

final class AppSystemEventFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    
    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .systemEvent
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct AppSystemEvent: BreadcrumbEvent {
    var timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    let eventType: String
    
    var type: BreadcrumbType { .systemEvent }
    
    var data: [BreadcrumbKeys : String] {
        [
            .event: event,
            .eventType: eventType
        ]
    }
}
