//
//  AppInstallEvent.swift
//  blue-triangle
//
//  Created by Ashok Singh on 27/02/26.
//

import Foundation

final class AppInstallFeature: BreadcrumbFeatrure {
    private let collector: BreadcrumbCollector
    init(collector: BreadcrumbCollector) {
        self.collector = collector
       
    }
    
    func canCollect(_ breadcrumb: any BreadcrumbEvent) -> Bool {
        breadcrumb.type == .appInstall
    }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        collector.collect(breadcrumb)
    }
}

struct AppInstallEvent: BreadcrumbEvent {
    var timestamp: Millisecond = Date().timeIntervalSince1970.milliseconds
    let version: String
    var type: BreadcrumbType { .appInstall }
    
    var data: [BreadcrumbKeys : String] {
        [
            .version: version
        ]
    }
}
