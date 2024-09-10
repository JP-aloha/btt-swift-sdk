//
//  ConfigurationFetcher.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation
import Combine

protocol ConfigurationFetcher {
    func fetch(completion: @escaping (BTTRemoteConfig?) -> Void) 
}

class BTTConfigurationFetcher : ConfigurationFetcher {

    private var cancellables: Set<AnyCancellable>
    private let sessionConfig :  URLSession
    
    private var queue = DispatchQueue(label: "com.bluetriangle.fetcher",
                     qos: .userInitiated,
                     autoreleaseFrequency: .workItem)
    
    init(session : URLSession, cancellable : Set<AnyCancellable>) {
        self.sessionConfig = session
        self.cancellables = cancellable
    }
    
        
    func fetch(completion: @escaping (BTTRemoteConfig?) -> Void) {
        
        let session = sessionConfig
        let parameters = [
            "siteID": BlueTriangle.siteID
        ]
        
        let service = BTTService.init(
            baseURL: Constants.configBaseURL,
            networking: { request in
                session.dataTaskPublisher(for: request)
            })
        
        service.fetch(parameters)
            .subscribe(on: queue)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        break
                    case .failure(_):
                        completion(nil)
                    }
                },
                receiveValue: { remoteConfig in
                    completion(remoteConfig)
                }
            )
            .store(in: &cancellables)
    }
}
