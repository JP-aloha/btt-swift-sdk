//
//  URLSession+Networking.swift
//
//  Created by Mathew Gacy on 4/8/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension URLSession {
    static let live: Networking = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData // Disable caching explicitly
        configuration.urlCache = nil // Prevents disk/memory caching
        let userAgent = "\(Bundle.main.userAgentToken) \(Device.userAgentToken) \(BlueTriangle.sdkId)/\(Device.sdkVersion)"
        let encodedAgent = userAgent.unicodeScalars.map { scalar -> String in
            if scalar.isASCII {
                return String(scalar)
            } else {
                return "?"
            }
        }.joined()
            
        configuration.httpShouldSetCookies = false
        configuration.httpAdditionalHeaders = [
            "User-Agent": encodedAgent]

        let session = URLSession(configuration: configuration)
        return session.dataTaskPublisher
    }()
}
