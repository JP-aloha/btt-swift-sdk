//
//  NetworkRequestFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//


import Foundation

final class NetworkRequestFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector

    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .networkRequest
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct NetworkRequestEvent: BreadcrumbEvent {
    var timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
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
