//
//  MetricKitWatchDog.swift
//
//  Copyright © 2026 Blue Triangle. All rights reserved.
//

#if os(iOS)
import Foundation
import MetricKit

final class MetricKitWatchDog: NSObject {
    let session: SessionProvider
    let uploader: Uploading
    let logger: Logging
    let errorMetricStore = ErrorMetricStore()

    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.unitOptions = .providedUnit
        return formatter
    }()

    private var startupTask: Task<Void, Error>?

    /// When this watchdog actually started observing (subscribed to `MXMetricManager`). `didReceive(_:)`
    /// can fire with a payload whose collection window began *before* this - e.g. last session's crash,
    /// delivered promptly once this launch subscribes - which isn't "live" in any meaningful sense even
    /// though it arrives through the live-delivery callback. `processDiagnostics` uses this to downgrade
    /// such a payload to non-live instead of trusting the callback blindly.
    private(set) var observingSince: Date?

    init(session: @escaping SessionProvider, uploader: Uploading, logger: Logging) {
        self.session = session
        self.uploader = uploader
        self.logger = logger
    }

    func start() {
        self.observingSince = Date()
        self.startupTask = Task.delayed(byTimeInterval: Constants.startupDelay, priority: .utility) { [weak self] in
            defer { self?.startupTask = nil }
            guard let strongSelf = self else { return }
            MXMetricManager.shared.add(strongSelf)
            if #available(iOS 14.0, *) {
                let pastPayloads = MXMetricManager.shared.pastDiagnosticPayloads
                strongSelf.logger.debug("MetricKit Watch Dog: \(pastPayloads.count) past diagnostic payload(s) replayed on subscribe.")
                strongSelf.processDiagnostics(pastPayloads, isLive: false)
            }
        }
        logger.info("MetricKit Watch Dog started.")
    }

    func stop() {
        self.startupTask?.cancel()
        self.startupTask = nil
        MXMetricManager.shared.remove(self)
        logger.info("MetricKit Watch Dog stopped.")
    }

    deinit {
        MXMetricManager.shared.remove(self)
    }
}

// MARK: - MXMetricManagerSubscriber
extension MetricKitWatchDog: MXMetricManagerSubscriber {
    func didReceive(_ payloads: [MXMetricPayload]) {
        // Periodic performance metrics (battery, CPU, disk, etc.) - not surfaced to Blue Triangle today.
    }

    @available(iOS 14.0, *)
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        logger.debug("MetricKit Watch Dog: \(payloads.count) diagnostic payload(s) delivered live.")
        processDiagnostics(payloads, isLive: true)
    }
}
#endif
