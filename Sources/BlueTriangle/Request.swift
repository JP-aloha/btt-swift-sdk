//
//  Request.swift
//
//  Created by Mathew Gacy on 10/13/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

struct Request: Codable, URLRequestConvertible {
    /// The query items for a request URL.
    typealias Parameters = [String: String]

    /// The HTTP header fields for a request.
    typealias Headers = [String: String]

    /// The HTTP request method.
    let method: HTTPMethod
    /// The URL of the request.
    let url: URL
    /// The query items for the request URL.
    let parameters: Parameters?
    /// The HTTP header fields for a request.
    let headers: Headers?
    /// The data sent as the message body of a request, such as for an HTTP POST request.
    let body: Data?
    
    let accept: ContentType?
        
    let contentType: ContentType?

    /// The `URLQueryItem`s derived from ``parameters``.
    var queryItems: [URLQueryItem]? {
        parameters?.map { URLQueryItem(name: $0.0, value: $0.1) }
    }

    /// Creates a request.
    /// - Parameters:
    ///   - method: The HTTP method for the request.
    ///   - url: The URL for the request.
    ///   - parameters: The query items for the request URL.
    ///   - headers: The HTTP header fields for the request.
    ///   - body: The data for the request body.
    init(method: HTTPMethod, url: URL, parameters: Parameters? = nil, headers: Headers? = nil, body: Data? = nil, accept : ContentType? = nil, contentType : ContentType? = nil) {
        self.method = method
        self.url = url
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.accept = accept
        self.contentType = contentType
    }

    /// Returns a ``URLRequest`` created from this request.
    /// - Returns: The URL request instance.
    func asURLRequest() -> URLRequest {
        var urlRequest: URLRequest
        if let queryItems = queryItems,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = queryItems
            urlRequest = URLRequest(url: components.url!)
        } else {
            urlRequest = URLRequest(url: url)
        }

        if let accept {
            urlRequest.setValue(accept.rawValue, forHTTPHeaderField: "Accept")
        }

        if let contentType {
            urlRequest.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest.httpMethod = method.rawValue

        urlRequest.allHTTPHeaderFields = headers

        // body *needs* to be the last property that we set, because of this bug: https://bugs.swift.org/browse/SR-6687
        urlRequest.httpBody = body

        return urlRequest
    }
}

extension Request {
    /// Creates a request.
    /// - Parameters:
    ///   - method: The HTTP method for the request.
    ///   - url: The URL for the request.
    ///   - parameters: The query items for the request URL.
    ///   - headers: The HTTP header fields for the request.
    ///   - model: The model to be encoded as the body for the request.
    ///   - encode: The closure to encode the model for the request body.
    init<T: Encodable>(
        method: HTTPMethod = .post,
        url: URL,
        parameters: Parameters? = nil,
        headers: Headers? = nil,
        model: T,
        encode: (T) throws -> Data = { try JSONEncoder().encode($0).base64EncodedData() }
    ) throws {
        let body = try encode(model)
        self.init(method: method, url: url, parameters: parameters, headers: headers, body: body)
    }
}

extension Request {
        
    init(url: URL,
        body: Data? = nil,
        parameters: Parameters? = nil,
        headers: Headers? = nil,
        accept: ContentType? = nil,
        contentType: ContentType? = nil
    ) {
        self.init(method: .get, url: url, parameters: parameters, headers: headers, body: body,accept: accept, contentType: contentType)
    }
}

// MARK: - Supporting Types
extension Request {
    /// The HTTP Method.
    enum HTTPMethod: String, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }
    
    enum ContentType: String, Codable {
        case json = "application/json"
        case urlencoded = "application/x-www-form-urlencoded"
    }
}

// MARK: - Equatable
extension Request: Equatable {
    public static func == (lhs: Request, rhs: Request) -> Bool {
         lhs.method == rhs.method
            && lhs.url == rhs.url
            && lhs.headers == rhs.headers
            && lhs.body == rhs.body
    }
}

// MARK: - CustomStringConvertible
extension Request: CustomStringConvertible {
    var urlDescription: String {
        if let queryItems = queryItems,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.queryItems = queryItems
            return components.debugDescription
        } else {
            return url.absoluteString
        }
    }

    public var description: String {
        "\(method.rawValue) \(urlDescription) \(body != nil ? (String(data: body!, encoding: .utf8) ?? "") : "")"
    }
}

// MARK: - CustomDebugStringConvertible
extension Request: CustomDebugStringConvertible {
    var debugBodyDescription: String? {
        body?.base64DecodedData()?.prettyJson
    }

    public var debugDescription: String {
        "Request:\n" +
            "  \(method.rawValue) \(urlDescription) \n" +
            "  Body: \(debugBodyDescription ?? "")"
    }
}
