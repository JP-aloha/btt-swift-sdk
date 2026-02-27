//
//  BreadcrumCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//
import Foundation

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
            self.logger.info("BlueTriangle:BreadcrumbCollector - Added breadcrumb: \(breadcrumb)")
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
            var resultArray: [[String: Any]] = []
            for item in collected {
                guard
                    let object = try? JSONSerialization.jsonObject(with: item.data),
                    var dict = object as? [String: Any]
                else { continue }
                
                if let dataDict = dict.removeValue(forKey: "data") as? [String: Any] {
                    for (key, value) in dataDict {
                        dict[key] = value
                    }
                }
                resultArray.append(dict)
            }
            guard let finalData = try? JSONSerialization.data(withJSONObject: resultArray) else {
                return "[]"
            }
            return String(data: finalData, encoding: .utf8) ?? "[]"
        }
    }
    
    func clear() {
        queue.sync {
            self.collected.removeAll()
        }
    }
}
