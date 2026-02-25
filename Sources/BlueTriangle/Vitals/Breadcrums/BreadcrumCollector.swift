//
//  BreadcrumCollector.swift
//  blue-triangle
//
//  Created by Ashok Singh on 25/02/26.
//
import Foundation

final class BreadcrumCollector {
    
    private var collected: [(event: any BreadcrumEvent, data: Data, size: Int)] = []
    private var currentSize: Int = 0
    
    private let maxSize = 100 * 1024 // 100 KB
    private let encoder = JSONEncoder()
    private let logger: Logging
    
    init(logger: Logging) { self.logger = logger }
    
    func collect(_ breadcrumb: any BreadcrumEvent) {
        guard let encoded = try? encoder.encode(breadcrumb) else { return }
        
        let size = encoded.count
        
        // Ignore if single event exceeds 100KB
        guard size <= maxSize else { return }
        
        collected.append((breadcrumb, encoded, size))
        currentSize += size
        
        logger.info("BlueTriangle:BreadcrumCollector - Added breadcrums : \(breadcrumb)")
        trimIfNeeded()
    }
    
    private func trimIfNeeded() {
        while currentSize > maxSize, !collected.isEmpty {
            let removed = collected.removeFirst()
            currentSize -= removed.size
        }
    }
    
    /// Return typed breadcrumbs
    func breadrums() -> [any BreadcrumEvent] {
        collected.map { $0.event }
    }
    
    func clear() {
        collected.removeAll()
        currentSize = 0
    }
}
