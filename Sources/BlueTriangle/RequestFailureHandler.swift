//
//  RequestFailureHandler.swift
//
//  Created by Mathew Gacy on 6/12/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Combine
import Foundation
import Network

final class RequestFailureHandler: RequestFailureHandling {
    private var persistence: RequestCache
    private let logger: Logging
    private let networkMonitor: NWPathMonitor
    private var cancellables = Set<AnyCancellable>()
    static var isUploading : Bool = false
    var send: (() -> Void)?


    init(persistence: RequestCache, logger: Logging) {
        self.persistence = persistence
        self.logger = logger
        self.networkMonitor = NWPathMonitor()
    }

    convenience init?(file: File?, logger: Logging) {
        guard let file = file else {
            return nil
        }
        self.init(
            persistence: RequestCache(persistence: Persistence(file: file)),
            logger: logger)
    }

    func configureSubscriptions(queue: DispatchQueue) {
        networkMonitor.publisher(queue: queue)
            .filter { $0.status == .satisfied }
            .sink { [weak self] status in
                self?.sendSaved()
            }.store(in: &cancellables)

#if !os(watchOS)
        NotificationCenter.default.publisher(for: .willTerminate)
            .sink { [weak self] _ in
                do {
                    try self?.persistence.saveBuffer()
                } catch {
                    self?.log(error)
                }
            }.store(in: &cancellables)
#endif
    }

    func store(request: Request) {
        do {
            try persistence.save(request)
        } catch {
            log(error)
        }
    }

    func migrateCache() {
        do {
            guard let requests = try persistence.read() else { return }
            let cache = BlueTriangle.payloadCache
            requests.forEach {
                do {
                    try cache.save(Payload(request: $0))
                } catch{ log(error) }
            }
            try persistence.clear()
        } catch {
            log(error)
        }
    }
    
    func sendSaved() {
        
        if !RequestFailureHandler.isUploading {
           
            RequestFailureHandler.isUploading = true
            
            self.migrateCache()
            
            if let send = send{
                send()
            }
        }
    }

    private func log(_ error: Error) {
        let message = (error as? PersistenceError)?.localizedDescription ?? error.localizedDescription
        logger.error(message)
    }
}
