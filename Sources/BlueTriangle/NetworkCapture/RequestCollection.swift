//
//  RequestCollection.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct RequestCollection: Equatable {
    let page: Page
    let startTime: Millisecond
    var requests: [CapturedRequest]

    var isNotEmpty: Bool {
        !requests.isEmpty
    }

    init(page: Page, startTime: Millisecond, requests: [CapturedRequest] = []) {
        self.page = page
        self.startTime = startTime
        self.requests = requests
    }

    mutating func insert(timer: InternalTimer, response: URLResponse?) {
        requests.append(CapturedRequest(timer: timer, relativeTo: startTime, response: response))
    }

    mutating func insert(metrics: URLSessionTaskMetrics) {
        requests.append(CapturedRequest(metrics: metrics, relativeTo: startTime))
    }

    mutating func batchRequests() -> [CapturedRequest]? {
        guard isNotEmpty else {
            return nil
        }
        defer { requests = [] }
        return requests
    }
}

// MARK: - CustomStringConvertible
extension RequestCollection: CustomStringConvertible {
    var description: String {
        "RequestCollection(pageName: \(page.pageName), requestCount: \(requests.count)"
    }
}