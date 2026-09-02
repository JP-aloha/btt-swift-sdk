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
    static func save<T: Codable>(_ record: T, key: UserDefaultsUtility.UserDefaultKeys) {
        UserDefaultsUtility.saveCodable(record, key: key)
        print("PendingCrashRecordStore Saved properly")
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

    static func consume(matchingCrashTime crashTime: Millisecond?, key: UserDefaultsUtility.UserDefaultKeys = .pendingCrashRecord) -> PendingCrashRecord? {
        guard let record = UserDefaultsUtility.loadCodable(PendingCrashRecord.self, key: key) else {
            return nil
        }
        if let crashTime, let recordCrashTime = record.crashTime, crashTime != recordCrashTime {
            return nil
        }
        UserDefaultsUtility.removeData(key: key)
        return record
    }

    static func removeExpiredCrashRecord(key: UserDefaultsUtility.UserDefaultKeys = .pendingCrashRecord) {
        guard let record = UserDefaultsUtility.loadCodable(PendingCrashRecord.self, key: key),
              let crashTime = record.crashTime
        else { return }
        let ageSeconds = Date().timeIntervalSince1970 - TimeInterval(crashTime) / 1000
        if ageSeconds > Constants.pendingCrashRecordExpiry {
            UserDefaultsUtility.removeData(key: key)
        }
    }
}
