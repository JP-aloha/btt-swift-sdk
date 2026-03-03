//
//  UserEventFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 02/03/26.
//


import Foundation

final class UserEventFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .userEvent
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct UserEvent : BreadcrumbEvent {
    let timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let targetClass: String
    let targetId: String
    let action: String
    var type: BreadcrumbType { .userEvent }
    
    var data: [BreadcrumbKeys : String] {
        [
            .action: action,
            .targetClass: targetClass,
            .targetId: targetId
        ]
    }
}
