//
//  BreadcrumCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//
import Foundation

final class BreadcrumbCollector {
    
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.collector")
    private var collected: [(event: any BreadcrumbEvent, data: Data, size: Int)] = []
    private var currentSize: Int = 0
    
    private let maxSize = 100 * 1024 // 100 KB
    private let encoder = JSONEncoder()
    private let logger: Logging
    
    init(logger: Logging) { self.logger = logger }
    
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        queue.async {
            guard let encoded = try? self.encoder.encode(breadcrumb) else { return }
            
            let size = encoded.count
            
            // Ignore if single event exceeds 100KB
            guard size <= self.maxSize else { return }
            
            self.collected.append((breadcrumb, encoded, size))
            self.currentSize += size
            
            self.logger.info("BlueTriangle:BreadcrumCollector - Added breadcrums : \(breadcrumb)")
            self.trimIfNeeded()
        }
    }
    
    private func trimIfNeeded() {
        while currentSize > maxSize, !collected.isEmpty {
            let removed = collected.removeFirst()
            currentSize -= removed.size
        }
    }
    
    /// Return typed breadcrumbs
    func breadrumbs() -> [any BreadcrumbEvent] {
        queue.sync {
            self.collected.map { $0.event }
        }
    }
    
    func breadrumbsString() -> String {
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
            self.currentSize = 0
        }
    }
}
