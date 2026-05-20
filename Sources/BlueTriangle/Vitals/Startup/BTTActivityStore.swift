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

    // MARK: - Public
    func updatePageDetail() {
        queue.async {
            guard let timer = BlueTriangle.recentTimer() else { return }
            let name = timer.getPageName()
            let segment = timer.getTrafficSegment()
            let type = timer.page.pageType
            
            if !name.isEmpty { self.pageName = name}
            if !segment.isEmpty { self.trafficSegment = segment}
            if !type.isEmpty { self.pageType = type }
        }
    }

    func save() {
        queue.sync {
            self.deleteExisting()
            let ts = Int64(Date().timeIntervalSince1970 * 1000)
            let filename = "\(self.prefix)\(ts)\(self.separator)\(self.pageName)\(self.separator)\(self.trafficSegment)\(self.separator)\(self.pageType)"
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
            return ActivityRecord(
                date: Date(timeIntervalSince1970: ts / 1000),
                pageName: parts[1],
                trafficSegment: parts[2],
                pageType: parts[3]
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
}
