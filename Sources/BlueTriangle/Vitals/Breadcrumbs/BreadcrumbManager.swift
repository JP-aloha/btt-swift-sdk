//
//  BreadcrumbManager.swift
//  blue-triangle
//
//  Created by Ashok Singh on 26/02/26.
//
import Foundation

enum BreadcrumbsFeature: String {
    case appLifecycle = "AppLifecycle"
    case uiLifecycle = "UiLifecycle"
    case networkRequest = "NetworkRequest"
    case networkState = "NetworkState"
    case appInstall = "AppInstall"
    case systemEvent = "SystemEvent"
    case appUpdate = "AppUpdate"
    case userEvent = "UserEvent"
}

final class BreadcrumbManager {
    
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.manager", attributes: .concurrent)
    private let collector: BreadcrumbCollector
    private var features: [BreadcrumbFeatrure] = []
    
    init(collector: BreadcrumbCollector) {
        self.collector = collector
        self.updateBreadcrumbFeatures()
    }
    
    func updateBreadcrumbFeatures() {
        let ignoredBreadcrumbs = BlueTriangle.configuration.ignoreBreadcrumbs.map { $0.lowercased() }
        let enableTabDetection = BlueTriangle.configuration.enableGroupingTapDetection
        var newFeatures: [BreadcrumbFeatrure] = []
        
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.appInstall.rawValue.lowercased()) {
            newFeatures.append(AppInstallFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.systemEvent.rawValue.lowercased()) {
            newFeatures.append(AppSystemEventFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.appUpdate.rawValue.lowercased()) {
            newFeatures.append(AppUpdateFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.appLifecycle.rawValue.lowercased()) {
            newFeatures.append(AppLifecycleFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.uiLifecycle.rawValue.lowercased()) {
            newFeatures.append(UILifecycleFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.networkRequest.rawValue.lowercased()) {
            newFeatures.append(NetworkRequestFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.networkState.rawValue.lowercased()) {
            newFeatures.append(NetworkStateFeature(collector: collector))
        }
        if !ignoredBreadcrumbs.contains(BreadcrumbsFeature.userEvent.rawValue.lowercased()) && enableTabDetection {
            newFeatures.append(UserEventFeature(collector: collector))
        }
        
        // Single atomic barrier read/write
        queue.async(flags: .barrier) {
            self.features = newFeatures
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
    
    func saveBreadcrumbsToDisk() {
        queue.sync {
            collector.saveBreadcrumbsToDisk()
        }
    }
}
