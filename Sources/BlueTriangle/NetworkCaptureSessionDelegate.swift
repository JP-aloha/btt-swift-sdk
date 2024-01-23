//
//  NetworkCaptureSessionDelegate.swift
//
//  Created by Mathew Gacy on 11/10/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

/// A session delegate that supports capturing network requests.
open class NetworkCaptureSessionDelegate: NSObject, URLSessionTaskDelegate {

    /// Tells the delegate that the session finished collecting metrics for the task.
    ///
    /// You can override this method to perform additional tasks associated with the collected
    /// metrics. If you override this method, you must call `super` at some point in your
    /// implementation.
    ///
    /// - Parameters:
    ///   - session: The session collecting the metrics.
    ///   - task: The task whose metrics have been collected.
    ///   - metrics: The collected metrics.
    open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
        BlueTriangle.captureRequest(metrics: metrics, error: task.error)
    }
}
