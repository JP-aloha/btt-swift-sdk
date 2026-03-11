//
//  BreadcrumCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//
import Foundation
#if canImport(AppEventLogger)
import AppEventLogger
#endif

final class BreadcrumbCollector {
    
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.collector")
    private var collected: [(event: any BreadcrumbEvent, data: Data)] = []
    private let maxItems = 100
    private let encoder = JSONEncoder()
    private let logger: Logging
    
    init(logger: Logging) { self.logger = logger }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        queue.async {
            guard let encoded = try? self.encoder.encode(breadcrumb) else { return }
            self.collected.append((breadcrumb, encoded))
            self.trimIfNeeded()
            SignalHandler.setBreadcrumbs(self.generateBreadcrumbsString(true))
            
            if breadcrumb is UserEvent {
                self.logger.debug("BlueTriangle:BreadcrumbCollector - Added breadcrumb: \(breadcrumb)")
            }
        }
    }
    
    private func trimIfNeeded() {
        while collected.count > maxItems {
            collected.removeFirst()
        }
    }
    
    /// Return typed breadcrumbs
    func breadrumbs() -> [any BreadcrumbEvent] {
        queue.sync {
            self.collected.map { $0.event }
        }
    }
    
    func breadcrumbsString() -> String {
        queue.sync {
            generateBreadcrumbsString()
        }
    }
    
    private func generateBreadcrumbsString(_ escaped: Bool = false) -> String {
        var resultArray: [[String: Any]] = []

        for item in collected {
            guard
                let object = try? JSONSerialization.jsonObject(with: item.data),
                var dict = object as? [String: Any]
            else { continue }

            if let dataDict = dict.removeValue(forKey: "data") as? [String: Any] {
                dict.merge(dataDict) { _, new in new }
            }

            resultArray.append(dict)
        }

        guard JSONSerialization.isValidJSONObject(resultArray),
              let data = try? JSONSerialization.data(withJSONObject: resultArray),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        guard escaped else {
            return jsonString
        }

        return jsonString
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    func clear() {
        queue.sync {
            self.collected.removeAll()
        }
    }
}
