//
//  AppLifecycleFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//
import Foundation

final class AppLifecycleFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .appLifecycle
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct AppLifecycleEvent: BreadcrumbEvent {
    var timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let event: String
    var type: BreadcrumbType { .appLifecycle }
    
    var data: [BreadcrumbKeys : String] {
        [.event: event]
    }
}
