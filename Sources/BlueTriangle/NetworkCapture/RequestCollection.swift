//
//  RequestCollection.swift
//
//  Created by Mathew Gacy on 3/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct RequestCollection: Equatable {
    let page: Page
    var startTime: Millisecond
    var isGroupTimer: Bool
    var requests: [CapturedRequest]

    var isNotEmpty: Bool {
        !requests.isEmpty
    }

    init(page: Page, startTime: Millisecond, isGroupTimer: Bool = false, requests: [CapturedRequest] = []) {
        self.page = page
        self.startTime = startTime
        self.requests = requests
        self.isGroupTimer = isGroupTimer
    }
    
    mutating func updateNetworkCapture(pageName : String, startTime: Millisecond) {
        if isGroupTimer {
            self.page.pageName = pageName
            self.startTime = startTime
        }
    }
    
    mutating func insert(timer: InternalTimer, response: URLResponse?, method: String? = nil) {
        requests.append(CapturedRequest(timer: timer, relativeTo: startTime, response: response, method: method))
    }
    
    mutating func insert(timer: InternalTimer, request: URLRequest?, error: Error?) {
        requests.append(CapturedRequest(timer: timer, relativeTo: startTime, request: request, error: error))
    }
    
    mutating func insert(timer: InternalTimer, response: CustomResponse) {
        requests.append(CapturedRequest(timer: timer, relativeTo: startTime, response: response))
    }

    mutating func insert(metrics: URLSessionTaskMetrics, error: Error?) {
        requests.append(CapturedRequest(metrics: metrics, relativeTo: startTime, error: error))
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
