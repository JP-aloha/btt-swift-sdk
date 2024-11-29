//
//  ConfigurationFetcher.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

protocol ConfigurationFetcher {
    func fetch(completion: @escaping (BTTRemoteConfig? , NetworkError?) -> Void)
}

class BTTConfigurationFetcher : ConfigurationFetcher {

    private let decoder: JSONDecoder = .decoder
    private var queue = DispatchQueue(label: "com.bluetriangle.fetcher",
                     qos: .userInitiated,
                     autoreleaseFrequency: .workItem)
    
    private let rootUrl :  URL
    private var networking :  Networking
    private var cancellables: Set<AnyCancellable>
    
    init(rootUrl : URL = Constants.connfigEndPoint,
         cancellable : Set<AnyCancellable> = Set<AnyCancellable>(),
         networking : @escaping Networking = URLSession.live){
        self.rootUrl = rootUrl
        self.cancellables = cancellable
        self.networking = networking
    }
  
    func fetch(completion: @escaping (BTTRemoteConfig?, NetworkError?) -> Void) {
        self.fetchRemoteConfig()
            .subscribe(on: queue)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        break
                    case .failure( let error):
                        completion(nil, error)
                    }
                },
                receiveValue: { remoteConfig in
                    completion(remoteConfig, nil)
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchRemoteConfig() -> AnyPublisher<BTTRemoteConfig, NetworkError> {
        let parameters = [
            "siteID": BlueTriangle.siteID
        ]
        let request = Request(url: rootUrl, parameters: parameters, accept: .json)
        return networking(request)
            .tryMap { httpResponse in
                return try httpResponse.validate()
                    .decode(with: self.decoder)
            }
            .mapError {NetworkError.wrap($0)}
            .eraseToAnyPublisher()
    }
}
