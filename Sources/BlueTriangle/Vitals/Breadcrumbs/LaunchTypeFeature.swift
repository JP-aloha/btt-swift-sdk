//
//  LaunchTypeFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 27/02/26.
//


import Foundation

final class LaunchTypeFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector

    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .launchType
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct LaunchTypeEvent: BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let launchType: String
    
    var type: BreadcrumbType { .launchType }
    
    var data: [BreadcrumbKeys : String] {
        [
            .launchType: launchType
        ]
    }
}
