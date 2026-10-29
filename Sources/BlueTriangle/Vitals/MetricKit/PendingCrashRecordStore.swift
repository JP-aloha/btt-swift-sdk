//
//  PendingCrashRecordStore.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

import Foundation

struct PendingCrashRecord: Codable {
    let sessionID: Identifier
    let pageName: String?
    let trafficSegment: String?
    let pageType: String?
    let breadcrumbs: String?
    let crashTime: Millisecond?
}

enum PendingCrashRecordStore {
    /// Crash times are captured with second precision (`time(NULL)` / truncated `Date`), so two
    /// records - or a record and a signpost - within this window describe the same crash.
    static let crashTimeTolerance: Millisecond = 1000
    private static let lock = NSLock()

    static func save<T: Codable>(_ record: T, key: UserDefaultsUtility.UserDefaultKeys) {
        UserDefaultsUtility.saveCodable(record, key: key)
    }

    static func load<T: Codable>(_ type: T.Type, key: UserDefaultsUtility.UserDefaultKeys) -> T? {
        UserDefaultsUtility.loadCodable(type, key: key)
    }

    static func remove(key: UserDefaultsUtility.UserDefaultKeys) {
        UserDefaultsUtility.removeData(key: key)
    }

    static func consume<T: Codable>(_ type: T.Type, key: UserDefaultsUtility.UserDefaultKeys) -> T? {
        guard let record = UserDefaultsUtility.loadCodable(type, key: key) else { return nil }
        UserDefaultsUtility.removeData(key: key)
        return record
    }

    // MARK: - Crash records
    static func append(_ record: PendingCrashRecord) {
        lock.lock()
        defer { lock.unlock() }
        var records = loadCrashRecords()
        let isDuplicate = records.contains {
            $0.sessionID == record.sessionID && isSameCrashTime($0.crashTime, record.crashTime)
        }
        guard !isDuplicate else { return }
        records.append(record)
        saveCrashRecords(records)
    }

    /// Removes and returns the record belonging to one MetricKit crash diagnostic.
    static func consume(matchingCrashTime crashTime: Millisecond?) -> PendingCrashRecord? {
        lock.lock()
        defer { lock.unlock() }
        var records = loadCrashRecords()
        let index: Int?
        if let crashTime {
            index = records.firstIndex { isSameCrashTime($0.crashTime, crashTime) }
        } else {
            index = records.count == 1 ? 0 : nil
        }
        guard let index else { return nil }
        let record = records.remove(at: index)
        saveCrashRecords(records)
        return record
    }

    static func removeExpiredCrashRecords(now: TimeInterval = Date().timeIntervalSince1970) {
        lock.lock()
        defer { lock.unlock() }
        let records = loadCrashRecords()
        let unexpired = records.filter { record in
            guard let crashTime = record.crashTime else { return true }
            return now - TimeInterval(crashTime) / 1000 <= Constants.pendingCrashRecordExpiry
        }
        guard unexpired.count != records.count else { return }
        saveCrashRecords(unexpired)
    }

    // MARK: - Private

    /// Also reads the single-record format this key held before records were kept as a list.
    private static func loadCrashRecords() -> [PendingCrashRecord] {
        guard let data = UserDefaultsUtility.getData(type: Data.self, forKey: .pendingCrashRecord) else { return [] }
        let decoder = JSONDecoder()
        if let records = try? decoder.decode([PendingCrashRecord].self, from: data) {
            return records
        }
        if let record = try? decoder.decode(PendingCrashRecord.self, from: data) {
            return [record]
        }
        UserDefaultsUtility.removeData(key: .pendingCrashRecord)
        return []
    }

    private static func saveCrashRecords(_ records: [PendingCrashRecord]) {
        if records.isEmpty {
            UserDefaultsUtility.removeData(key: .pendingCrashRecord)
        } else {
            UserDefaultsUtility.saveCodable(records, key: .pendingCrashRecord)
        }
    }

    private static func isSameCrashTime(_ lhs: Millisecond?, _ rhs: Millisecond?) -> Bool {
        guard let lhs, let rhs else { return lhs == nil && rhs == nil }
        return abs(lhs - rhs) <= crashTimeTolerance
    }
}
