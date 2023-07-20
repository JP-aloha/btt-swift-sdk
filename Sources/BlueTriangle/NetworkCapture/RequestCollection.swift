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
    var requests: [CapturedRequest] = []
    private(set) var firstRequestStartTime : Millisecond?
    
    var isNotEmpty: Bool {
        !requests.isEmpty
    }

    init(page: Page, startTime: Millisecond) {
        self.page = page
        self.startTime = startTime
    }

    mutating func insert(timer: InternalTimer, response: URLResponse?) {
        let relativeTo = firstRequestStartTime ?? timer.startTime.milliseconds
        self.appendRequest(r: [CapturedRequest(timer: timer, relativeTo: relativeTo, response: response)],
                           startTime: relativeTo)
    }

    mutating func insert(metrics: URLSessionTaskMetrics) {
        let relativeTo = firstRequestStartTime ?? metrics.taskInterval.start.timeIntervalSince1970.milliseconds
        self.appendRequest(r: [CapturedRequest(metrics: metrics, relativeTo: relativeTo)],
                           startTime: relativeTo)
    }

    mutating func batchRequests() -> [CapturedRequest]? {
        guard isNotEmpty else {
            return nil
        }
        defer { requests = [] }
        return requests
    }
 
    private mutating func appendRequest(r : [CapturedRequest], startTime: Millisecond){
        requests.append(contentsOf: r)
        //The Start Time of the Network Capture data (wcdv02.rcv) should reset to zero for the first network call on the screen/view.
        if firstRequestStartTime == nil{
            firstRequestStartTime = startTime
        }
    }
}

// MARK: - CustomStringConvertible
extension RequestCollection: CustomStringConvertible {
    var description: String {
        "RequestCollection(pageName: \(page.pageName), requestCount: \(requests.count)"
    }
}
