//
//  NetworkStateFeature.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//
import Foundation

final class NetworkStateFeature: BreadcrumbFeatrure {
   
    private let collector: BreadcrumbCollector

    init(collector: BreadcrumbCollector) {
        self.collector = collector
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .networkState
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
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
