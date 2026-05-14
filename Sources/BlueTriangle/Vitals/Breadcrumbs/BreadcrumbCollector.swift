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

// MARK: - Placeholder (event slot only — data is read from jsonData directly)
private struct PlaceholderBreadcrumb: BreadcrumbEvent {
    var timestamp: Millisecond = 0
    var type: BreadcrumbType = .userEvent
    var data: [BreadcrumbKeys: String] = [:]
}

// MARK: - BreadcrumbCollector
final class BreadcrumbCollector {
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.collector")
    private var collected: [(event: any BreadcrumbEvent, data: Data)] = []
    private let maxItems = Constants.Breadcrums.Default.capacity
    private let encoder = JSONEncoder()
    private let logger: Logging
    private let diskStore = BreadcrumbDiskStore()

    init(logger: Logging) {
        self.logger = logger
        loadFromDisk()
    }

    // MARK: - Public
    func collect(_ breadcrumb: any BreadcrumbEvent) {
        queue.async {
            guard let encoded = try? self.encoder.encode(breadcrumb) else { return }
            self.collected.append((breadcrumb, encoded))
            self.trimIfNeeded()
            SignalHandler.setBreadcrumbs(self.generateBreadcrumbsString(true))
            self.logger.debug("BlueTriangle:BreadcrumbCollector - Added breadcrumb: \(breadcrumb)")
        }
    }

    func breadrumbs() -> [any BreadcrumbEvent] {
        queue.sync { collected.map { $0.event } }
    }

    func breadcrumbsString() -> String {
        queue.sync { generateBreadcrumbsString() }
    }

    func clear() {
        queue.sync { collected.removeAll() }
    }
    
    func saveBreadcrumbsToDisk() {
        queue.sync { diskStore.save(collected.map(\.data)) }
    }

    // MARK: - Private
    private func loadFromDisk() {
        guard let items = diskStore.load() else { return }
        collected = items.compactMap { jsonData in
            guard let obj = try? JSONSerialization.jsonObject(with: jsonData),
                  let dict = obj as? [String: Any],
                  let reEncoded = try? JSONSerialization.data(withJSONObject: dict)
            else { return nil }
            return (event: PlaceholderBreadcrumb(), data: reEncoded)
        }
        logger.debug("BlueTriangle:BreadcrumbCollector - Loaded \(self.collected.count) breadcrumbs from disk")
    }

    private func trimIfNeeded() {
        while collected.count > maxItems {
            collected.removeFirst()
        }
    }

    private func generateBreadcrumbsString(_ escaped: Bool = false) -> String {
        var resultArray: [[String: Any]] = []
        for item in collected {
            guard let obj = try? JSONSerialization.jsonObject(with: item.data),
                  var dict = obj as? [String: Any]
            else { continue }
            if let nested = dict.removeValue(forKey: "data") as? [String: Any] {
                dict.merge(nested) { _, new in new }
            }
            resultArray.append(dict)
        }
        guard !resultArray.isEmpty,
              JSONSerialization.isValidJSONObject(resultArray),
              let data = try? JSONSerialization.data(withJSONObject: resultArray),
              let json = String(data: data, encoding: .utf8)
        else { return "" }

        return escaped ? json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") : json
    }
}

// MARK: - Disk Store
final class BreadcrumbDiskStore {
    private static let fileURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("com.bluetriangle.breadcrumbs.bplist")
    }()

    func save(_ items: [Data]) {
        guard let data = try? PropertyListEncoder().encode(items) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    func load() -> [Data]? {
        guard let data = try? Data(contentsOf: Self.fileURL) else { return nil }
        return try? PropertyListDecoder().decode([Data].self, from: data)
    }
}

