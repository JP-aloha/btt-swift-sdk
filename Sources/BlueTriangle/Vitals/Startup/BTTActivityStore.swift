//
//  BTTActivityStore.swift
//  blue-triangle
//
//  Created by Ashok Singh on 20/05/26.
//

import Foundation

final class BTTActivityStore {

    private let queue = DispatchQueue(label: "com.bluetriangle.activitystore")
    private let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    private let prefix = "bttlt_"
    private let separator = "~"
    private var pageName = Constants.APP_INSTALL_PAGE_GROUP
    private var trafficSegment = Constants.defaultTraficSegment
    private var pageType = Constants.defaultPageType
    /// The page's own nStart, as a raw `Millisecond` - kept as milliseconds end-to-end (captured,
    /// persisted, and read back) rather than round-tripped through `TimeInterval` (seconds, as a
    /// `Double`), since that round trip can drift by 1ms from floating-point rounding and then no
    /// longer match the parent page's own `nStart`.
    private var pageStartTime: Millisecond = 0

    // MARK: - Public
    func updatePageDetail() {
        queue.async {
            guard let timer = BlueTriangle.recentTimer() else { return }
            let name = timer.getPageName()
            let segment = timer.getTrafficSegment()
            let type = timer.page.pageType

            // `pageStartTime` must only ever change alongside `pageName`, from the same timer - never
            // on its own, otherwise a later timer with an empty page name would leave `pageName` on
            // its old value while `pageStartTime` jumped to the new timer's startTime, so the two
            // would no longer describe the same page.
            if !name.isEmpty {
                self.pageName = name
                self.pageStartTime = timer.startTime.milliseconds
            }
            if !segment.isEmpty { self.trafficSegment = segment}
            if !type.isEmpty { self.pageType = type }
        }
    }

    func save() {
        queue.sync {
            self.deleteExisting()
            let ts = Int64(Date().timeIntervalSince1970 * 1000)
            let filename = "\(self.prefix)\(ts)\(self.separator)\(self.pageName)\(self.separator)\(self.trafficSegment)\(self.separator)\(self.pageType)\(self.separator)\(self.pageStartTime)"
            let url = self.dir.appendingPathComponent(filename)
            FileManager.default.createFile(atPath: url.path,contents: nil)
        }
    }

    func get() -> ActivityRecord? {
        queue.sync {
            guard let filename = try? FileManager.default
                .contentsOfDirectory(atPath: dir.path)
                .first(where: { $0.hasPrefix(self.prefix) }) else {
                return nil
            }
            let stripped = String(filename.dropFirst(self.prefix.count))
            let parts = stripped.components(separatedBy: self.separator)
            guard parts.count >= 4, let ts = TimeInterval(parts[0]) else { return nil}
            // Falls back to the save timestamp for a record written before `pageStartTime` was
            // tracked (older SDK version), rather than failing to parse the whole record.
            let pageStartTime: Millisecond = parts.count >= 5 ? (Millisecond(parts[4]) ?? Millisecond(ts)) : Millisecond(ts)
            return ActivityRecord(
                date: Date(timeIntervalSince1970: ts / 1000),
                pageName: parts[1],
                trafficSegment: parts[2],
                pageType: parts[3],
                pageStartTime: pageStartTime
            )
        }
    }

    func clear() {
        queue.async {
            self.deleteExisting()
        }
    }

    // MARK: - Private
    private func deleteExisting() {
        guard let files = try? FileManager.default
            .contentsOfDirectory(atPath: dir.path)
            .filter({ $0.hasPrefix(self.prefix) }) else {
            return
        }

        files.forEach {
            try? FileManager.default.removeItem(
                at: self.dir.appendingPathComponent($0)
            )
        }
    }
}

// MARK: - Model
struct ActivityRecord {
    let date: Date
    let pageName: String
    let trafficSegment: String
    let pageType: String
    let pageStartTime: Millisecond
}
