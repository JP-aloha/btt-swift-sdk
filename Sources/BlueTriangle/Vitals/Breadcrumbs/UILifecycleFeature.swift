//
//  UILifecycleFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//

import Foundation

final class UILifecycleFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    
    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .uiLifecycle
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
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
