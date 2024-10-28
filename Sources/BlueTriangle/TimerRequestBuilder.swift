//
//  TimerRequestBuilder.swift
//
//  Created by Mathew Gacy on 6/15/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct TimerRequestBuilder {
    let builder: (Session, BTTimer, PurchaseConfirmation?) throws -> Request

    static func live(logger: Logging, encoder: JSONEncoder = .init()) -> Self {
        .init { session, timer, purchase in
            var customMetrics: String? = nil
            if let metrics = session.metrics {
                do {
                    let metricsData = try encoder.encode(metrics)

                    let base64MetricsData = metricsData.base64EncodedData()
                    if base64MetricsData.count > Constants.metricsSizeLimit {
                        let bcf = ByteCountFormatter()
                        bcf.includesActualByteCount = true

                        func formatted(_ count: Int) -> String {
                            bcf.string(fromByteCount: Int64(count))
                        }

                        logger.log("Custom metrics encoded size of \(formatted(base64MetricsData.count)) exceeds limit of \(formatted(Constants.metricsSizeLimit)); dropping from timer request.")
                    } else {
                        customMetrics = String(decoding: metricsData, as: UTF8.self)
                        if customMetrics?.count ?? 0 > Constants.metricsCharacterLimit {
                            logger.log("Custom metrics length is \(customMetrics?.count ?? 0) characters; exceeding \(Constants.metricsCharacterLimit) results in data loss.")
                        }
                    }
                } catch {
                    logger.log("Custom metrics encoding failed: \(error.localizedDescription)")
                }
            }

            let body = try encoder.encode(
                TimerRequest(session: session,
                             page: timer.page,
                             timer: timer.pageTimeInterval,
                             customMetrics: customMetrics,
                             purchaseConfirmation: purchase,
                             performanceReport: timer.performanceReport,
                             nativeAppProperties : timer.nativeAppProperties))

            return Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           body: body.base64EncodedData())
        }
    }
}
