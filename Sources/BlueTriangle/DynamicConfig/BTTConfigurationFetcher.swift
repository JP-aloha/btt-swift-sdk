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

    private let decoder: JSONDecoder = .decoder
    private var queue = DispatchQueue(label: "com.bluetriangle.fetcher",
                     qos: .userInitiated,
                     autoreleaseFrequency: .workItem)
    
    private let rootUrl :  URL
    private var networking :  Networking
    private var cancellables: Set<AnyCancellable>
    
    init(rootUrl : URL = Constants.configBaseURL,
         cancellable : Set<AnyCancellable> = Set<AnyCancellable>(),
         networking : @escaping Networking = URLSession.live){
        self.rootUrl = rootUrl
        self.cancellables = cancellable
        self.networking = networking
    }
  
    func fetch(completion: @escaping (BTTRemoteConfig?) -> Void) {
        self.fetchRemoteConfig()
            .subscribe(on: queue)
            .sink(
                receiveCompletion: { completionResult in
                    switch completionResult {
                    case .finished:
                        break
                    case .failure( let error):
                        print("Error while fetching : \(error.localizedDescription)")
                        completion(nil)
                    }
                },
                receiveValue: { remoteConfig in
                    completion(remoteConfig)
                }
            )
            .store(in: &cancellables)
    }
    
    private func fetchRemoteConfig() -> AnyPublisher<BTTRemoteConfig, Error> {
        let parameters = [
            "siteID": BlueTriangle.siteID
        ]
        let request = Request(url: rootUrl, parameters: parameters, accept: .json)
        return networking(request)
            .tryMap { httpResponse in
                return try httpResponse.validate()
                    .decode(with: self.decoder)
            }
            .eraseToAnyPublisher()
    }
}
