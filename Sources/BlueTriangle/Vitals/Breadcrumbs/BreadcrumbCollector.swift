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

    private struct Entry {
        var event: any BreadcrumbEvent
        var data: Data
        let key: String
        var count: Int
        var firstTimestamp: Millisecond
        var lastTimestamp: Millisecond
        let isMergeCandidate: Bool
    }

    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.collector")
    private static let swiftUIViewSuffix = " SwiftUI View"
    private var entries: [Entry] = []
    private let mergeWindow: Millisecond = 5000
    private let minOccurrencesBeforeCollapse = 5
    private let maxItems = Constants.Breadcrums.Default.capacity
    private let encoder = JSONEncoder()
    private let logger: Logging
    private let diskStore = BreadcrumbDiskStore()

    init(logger: Logging) {
        self.logger = logger
        loadFromDisk()
    }

    func collect(_ breadcrumb: any BreadcrumbEvent) {
        queue.async {
            guard let encoded = try? self.encoder.encode(breadcrumb) else { return }
            self.captures(event: breadcrumb, data: encoded, key: Self.mergeKey(for: breadcrumb))
            SignalHandler.setBreadcrumbs(self.generateBreadcrumbsString(true))
        }
    }

    func breadrumbs() -> [any BreadcrumbEvent] {
        queue.sync { entries.map { $0.event } }
    }

    func breadcrumbsString() -> String {
        queue.sync { generateBreadcrumbsString() }
    }

    func clear() {
        queue.sync {
            entries.removeAll()
        }
    }

    func saveBreadcrumbsToDisk() {
        queue.sync { diskStore.save(entries.map(\.data)) }
    }

    private func loadFromDisk() {
        guard let items = diskStore.load() else { return }
        entries = items.enumerated().compactMap { index, jsonData in
            guard let obj = try? JSONSerialization.jsonObject(with: jsonData),
                  let dict = obj as? [String: Any],
                  let reEncoded = try? JSONSerialization.data(withJSONObject: dict)
            else { return nil }
            return Entry(event: PlaceholderBreadcrumb(), data: reEncoded, key: "\(index)", count: 1, firstTimestamp: 0, lastTimestamp: 0, isMergeCandidate: false)
        }
        logger.debug("BlueTriangle:BreadcrumbCollector - Loaded \(self.entries.count) breadcrumbs from disk")
    }

    private func trimIfNeeded(relativeTo referenceTimestamp: Millisecond) {
        while true {
            let protectedIndices = protectedIndices(relativeTo: referenceTimestamp)
            guard entries.count - protectedIndices.count > maxItems else { break }
            guard let index = entries.indices.first(where: { !protectedIndices.contains($0) }) else { break }
            entries.remove(at: index)
        }
    }

    private func protectedIndices(relativeTo referenceTimestamp: Millisecond) -> Set<Int> {
        var groupedByKey: [String: [Int]] = [:]
        for (index, entry) in entries.enumerated() {
            guard entry.isMergeCandidate,
                  entry.count == 1,
                  referenceTimestamp - entry.firstTimestamp <= mergeWindow
            else { continue }
            groupedByKey[entry.key, default: []].append(index)
        }
        var protected = Set<Int>()
        for indices in groupedByKey.values where indices.count >= 2 {
            protected.formUnion(indices)
        }
        return protected
    }

    private static let swiftUILifecycleMethods: Set<String> = [
        Constants.Breadcrums.UILifeCycle.onAppear,
        Constants.Breadcrums.UILifeCycle.onDisappear
    ]

    private func captures(event: any BreadcrumbEvent, data: Data, key: String) {
        guard event.type == .uiLifecycle,
              let method = event.data[.event],
              Self.swiftUILifecycleMethods.contains(method) else {
            entries.append(Entry(event: event, data: data, key: key, count: 1, firstTimestamp: event.timestamp, lastTimestamp: event.timestamp, isMergeCandidate: false))
            self.trimIfNeeded(relativeTo: event.timestamp)
            return
        }

        // A group's window is fixed to `mergeWindow` from when it STARTED (firstTimestamp)
        let matchingIndices = entries.indices.filter {
            entries[$0].key == key && event.timestamp - entries[$0].firstTimestamp <= mergeWindow
        }

        // Derived from the entries actually still present — never a separately tracked
        // counter — so capacity trimming can never leave this out of sync with reality.
        let occurrence = matchingIndices.reduce(0) { $0 + entries[$1].count } + 1

        if occurrence >= minOccurrencesBeforeCollapse, let lastIndex = matchingIndices.last {
            let earliestTimestamp = matchingIndices.map { entries[$0].firstTimestamp }.min() ?? event.timestamp
            let baseData = entries[lastIndex].data
            for index in matchingIndices.reversed() {
                entries.remove(at: index)
            }
            let mergedData = Self.applyingCount(occurrence, timestamp: event.timestamp, to: baseData) ?? data
            entries.append(Entry(event: event, data: mergedData, key: key, count: occurrence, firstTimestamp: earliestTimestamp, lastTimestamp: event.timestamp, isMergeCandidate: true))
            self.trimIfNeeded(relativeTo: event.timestamp)
            return
        }
        entries.append(Entry(event: event, data: data, key: key, count: 1, firstTimestamp: event.timestamp, lastTimestamp: event.timestamp, isMergeCandidate: true))
        self.trimIfNeeded(relativeTo: event.timestamp)
    }

    private static func mergeKey(for breadcrumb: any BreadcrumbEvent) -> String {
        let sortedData = breadcrumb.data
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($0.key.rawValue)=\($0.value)" }
            .joined(separator: "&")
        return "\(breadcrumb.type.rawValue)|\(sortedData)"
    }

    private static func applyingCount(_ count: Int, timestamp: Millisecond, to data: Data) -> Data? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              var dict = obj as? [String: Any]
        else { return nil }

        dict[BreadcrumbKeys.timestamp.rawValue] = timestamp

        if var nested = dict[BreadcrumbKeys.data.rawValue] as? [String: Any],
           let className = nested[BreadcrumbKeys.className.rawValue] as? String {
            let name = rawClassName(from: className)
            nested[BreadcrumbKeys.className.rawValue] = count > 1 ? "\(count) \(name)\(swiftUIViewSuffix)" : name
            dict[BreadcrumbKeys.data.rawValue] = nested
        }

        guard JSONSerialization.isValidJSONObject(dict),
              let newData = try? JSONSerialization.data(withJSONObject: dict)
        else { return nil }
        return newData
    }

    private static func rawClassName(from value: String) -> String {
        var result = value
        if let range = result.range(of: #"^\d+ "#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        if result.hasSuffix(swiftUIViewSuffix) {
            result.removeLast(swiftUIViewSuffix.count)
        }
        return result
    }

    private func generateBreadcrumbsString(_ escaped: Bool = false) -> String {
        var resultArray: [[String: Any]] = []
        for entry in entries {
            guard let obj = try? JSONSerialization.jsonObject(with: entry.data),
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

final class BreadcrumbDiskStore {
    private let queue = DispatchQueue(label: "com.bluetriangle.breadcrumb.diskstore")
    private static let fileURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("com.bluetriangle.breadcrumbs.bplist")
    }()

    func save(_ items: [Data]) {
        queue.sync {
            guard let data = try? PropertyListEncoder().encode(items) else { return }
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    func load() -> [Data]? {
        queue.sync {
            guard let data = try? Data(contentsOf: Self.fileURL) else { return nil }
            return try? PropertyListDecoder().decode([Data].self, from: data)
        }
    }
}
