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
    /// POSIX signal of a signal crash; nil for an NSException crash.
    var signal: Int? = nil
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
    /// With a crash time (signpost), the record at that time is used, else the closest one in time.
    /// Without a crash time (no signpost), records with the diagnostic's `signal` are preferred (an
    /// NSException crash ends in SIGABRT), else any record (e.g. a crash the SDK did not catch).
    /// Of those, the ones whose crashTime falls inside `window` - the payload's time range - are
    /// preferred, else all of them (e.g. the app was not opened again until after the window), and
    /// the latest one is used.
    static func consume(
        matchingCrashTime crashTime: Millisecond?,
        signal: Int? = nil,
        within window: ClosedRange<Millisecond>? = nil
    ) -> PendingCrashRecord? {
        lock.lock()
        defer { lock.unlock() }
        var records = loadCrashRecords()
        let index: Int?
        if let crashTime {
            // No exact match: the record closest in time, NSException records first.
            let exceptionRecords = records.indices.filter { records[$0].signal == nil }
            let nearby = exceptionRecords.isEmpty ? Array(records.indices) : exceptionRecords
            index = records.firstIndex { isSameCrashTime($0.crashTime, crashTime) }
                ?? nearby.min { abs((records[$0].crashTime ?? 0) - crashTime) < abs((records[$1].crashTime ?? 0) - crashTime) }
        } else {
            let sameSignal = signal.map { signal in
                records.indices.filter { (records[$0].signal ?? Int(SIGABRT)) == signal }
            } ?? []
            let candidates = sameSignal.isEmpty ? Array(records.indices) : sameSignal
            let inWindow = window.map { window in
                candidates.filter { records[$0].crashTime.map { window.contains($0) } ?? false }
            } ?? []
            let matches = inWindow.isEmpty ? candidates : inWindow
            index = matches.max { (records[$0].crashTime ?? 0) < (records[$1].crashTime ?? 0) }
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
