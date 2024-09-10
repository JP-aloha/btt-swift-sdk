//
//  Service.swift
//  
//
//  Created by Ashok Singh on 05/09/24.
//

import Foundation
import Combine

struct BTTService {
   
   private let baseURL: URL
   private let decoder: JSONDecoder = .decoder
   private let networkingPub: (Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError>
   
   enum Route {
       case remoteconfig
       
       var path: String {
           switch self {
           case .remoteconfig:
               return "config.js"
           }
       }
   }
    
    init(
       baseURL: URL,
       networking: @escaping (Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError>
   ) {
       self.baseURL = baseURL
       self.networkingPub = networking
   }
   

    func fetch(_ queryItems: [String: String]) -> AnyPublisher<BTTRemoteConfig, Error> {
        let request = Request(url: url(for: .remoteconfig), parameters: queryItems, accept: .json)
        return networkingPub(request)
            .tryMap { httpResponse in
                return try httpResponse.validate()
                    .decode(with: self.decoder)
            }
            .eraseToAnyPublisher()
    }
}

private extension BTTService {
   func url(for route: Route) -> URL {
       baseURL.appendingPathComponent(route.path)
   }
}

