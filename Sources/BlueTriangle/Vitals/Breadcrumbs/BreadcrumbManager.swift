//
//  BreadcrumbManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//
import Foundation

final class BreadcrumbManager {
    
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.manager")
    private let collector: BreadcrumbCollector
    private var features: [BreadcrumbFeatrure] = []
    
    init(collector: BreadcrumbCollector) {
        self.collector = collector
        self.register(feature: LaunchTypeFeature(collector: collector))
        self.register(feature: AppInstallFeature(collector: collector))
        self.register(feature: AppUpdateFeature(collector: collector))
        self.register(feature: AppLifecycleFeature(collector: collector))
        self.register(feature: UILifecycleFeature(collector: collector))
        self.register(feature: NetworkRequestFeature(collector: collector))
        self.register(feature: NetworkStateFeature(collector: collector))
        self.register(feature: UserEventFeature(collector: collector))
    }
    
    private func register(feature: BreadcrumbFeatrure) {
        queue.sync {
            self.features.append(feature)
        }
    }
    
    func collectBreadcrumb(_ breadcrumb: any BreadcrumbEvent) {
        queue.sync {
            for feature in self.features where feature.canCollect(breadcrumb) {
                feature.collect(breadcrumb)
            }
        }
    }
    
    func breadcrumbs() -> String? {
        queue.sync {
            collector.breadcrumbsString()
        }
    }
}
