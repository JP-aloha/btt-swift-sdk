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
    var timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let from: String
    let to: String
    var type: BreadcrumbType { .appUpdate }
    
    var data: [BreadcrumbKeys : String] {
        [
            .from: from,
            .to: to
        ]
    }
}
