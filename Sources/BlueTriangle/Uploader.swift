//
//  Uploader.swift
//
//  Created by Mathew Gacy on 10/25/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

typealias Networking = (Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError>

final class Uploader: Uploading {
    private let lock = NSLock()

    private let queue: DispatchQueue

    private let logger: Logging

    private let networking: Networking

    private let failureHandler: RequestFailureHandling?

    private let retryConfiguration: RetryConfiguration<DispatchQueue>

    private var subscriptions = [UUID: AnyCancellable]()

     var subscriptionCount: Int {
         lock.sync { subscriptions.count }
     }

    init(
        queue: DispatchQueue,
        logger: Logging,
        networking: @escaping Networking,
        failureHandler: RequestFailureHandling?,
        retryConfiguration: RetryConfiguration<DispatchQueue>
    ) {
        self.queue = queue
        self.logger = logger
        self.networking = networking
        self.failureHandler = failureHandler
        self.retryConfiguration = retryConfiguration

        failureHandler?.send = { [weak self]  in
            self?.uploadCacheRequests()
        }
        failureHandler?.configureSubscriptions(queue: queue)
    }

    func send(request: Request) {
        logger.debug(request.debugDescription)
        let id = UUID()
        let cache = BlueTriangle.payloadCache
        let publisher = networking(request)
            .retry(retryConfiguration, scheduler: queue)
            .subscribe(on: queue)
            .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.logger.error(error.localizedDescription)
                        do{
                            try cache.save(Payload(request: request))
                        }catch{
                            self?.logger.error("Unable to save payload : \(error)")
                        }
                    }
                    
                    self?.removeSubscription(id: id)
                },
                receiveValue: { [weak self] value in
                    self?.logger.info("HTTP Status: \(value.response.statusCode)")
                }
            )

        addSubscription(publisher, id: id)
    }
    
    func uploadCacheRequests(){
        do{
            let cache = BlueTriangle.payloadCache
            if let payload = try cache.pickNext(){
                logger.debug(payload.data.debugDescription)
                let id = UUID()
                let publisher = networking(payload.data)
                    .subscribe(on: queue)
                    .sink(receiveCompletion: { [weak self] completion in
                        if case .failure( _) = completion {
                            self?.logger.debug(payload.data.debugDescription)
                            do{
                                try cache.save(payload)
                            }catch{
                                self?.logger.error("Unable to save payload : \(error)")
                            }
                            self?.uploadCacheRequests()
                        }
                        self?.removeSubscription(id: id)
                    },receiveValue: { [weak self] value in
                        self?.logger.info("HTTP Status: \(value.response.statusCode)")
                        do{
                            try cache.delete(payload)
                        }
                        catch{
                            self?.logger.error("Unable to delete payload : \(error)")
                        }
                        self?.uploadCacheRequests()
                    })
                
                addSubscription(publisher, id: id)
            }else{
                RequestFailureHandler.isUploading = false
            }
        }catch{
            RequestFailureHandler.isUploading = false
            self.logger.error("Unable to pick payload : \(error)")
        }
    }

    private func addSubscription(_ cancellable: AnyCancellable, id: UUID) {
        lock.sync { subscriptions[id] = cancellable }
    }

    private func removeSubscription(id: UUID) {
        lock.sync { subscriptions[id] = nil }
    }
}

// MARK: - Supporting Types
extension Uploader {
    struct RetryConfiguration<S: Scheduler> {
        let maxRetry: UInt
        let initialDelay: S.SchedulerTimeType.Stride
        let delayMultiplier: Double
        let shouldRetry: Publisher.RetryPredicate?
    }

    struct Configuration {
        let queue: DispatchQueue
        let networking: Networking
        let retryConfiguration: RetryConfiguration<DispatchQueue>

        func makeUploader(logger: Logging, failureHandler: RequestFailureHandling?) -> Uploading {
            Uploader(queue: queue,
                     logger: logger,
                     networking: networking,
                     failureHandler: failureHandler,
                     retryConfiguration: retryConfiguration)
        }

        static let live = Self(
            queue: DispatchQueue(label: "com.bluetriangle.uploader",
                                 qos: .userInitiated,
                                 autoreleaseFrequency: .workItem),
            networking: URLSession.live,
            retryConfiguration: .init(maxRetry: 3,
                                      initialDelay: 10.0,
                                      delayMultiplier: 1.0,
                                      shouldRetry: nil))
    }
}
