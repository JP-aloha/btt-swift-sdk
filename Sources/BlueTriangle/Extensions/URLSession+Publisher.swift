//
//  URLSession+Publisher.swift
//
//  Created by Mathew Gacy on 10/14/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation
import Combine

enum NetworkError: Error {
    /// Not a valid request.
    case malformedRequest
    /// Capture any underlying Error from the URLSession API.
    case network(error: Error)
    /// No data returned from server.
    case noData
    /// The server response was in an unexpected format.
    case invalidResponse(URLResponse?)
    /// There was a client error: 400-499.
    case clientError(HTTPURLResponse)
    /// There was a server error.
    case serverError(HTTPURLResponse)
    /// There was an error decoding the data.
    case decoding(error: Error)
    /// Unknown error.
    case unknown(message: String)

    /// Returns an appropriate network client error for the passed error.
    /// - Parameter error: A general error.
    /// - Returns: The network client error case corresponding to `error`.
    public static func wrap(_ error: Error) -> NetworkError {
        switch error {
        case let error as NetworkError:
            return error
        case is DecodingError:
            return .decoding(error: error)
        case is URLError:
            return .network(error: error)
        default:
            return .unknown(message: error.localizedDescription)
        }
    }
}

extension NetworkError {
    
    func getErrorMessage () -> String{
        
        var errorMessage = self.localizedDescription
        
        switch self {
            
        case .malformedRequest:
            errorMessage = "The request could not be created due to invalid parameters or formatting."

        case .network(error: let error):
            errorMessage = "A network error occurred: \(error.localizedDescription)."
        
        case .noData:
            errorMessage = "The response did not contain any data."
           
        case .invalidResponse(let urlResponse):
            errorMessage = "Received an invalid response for the URL: \(urlResponse?.url?.absoluteString ?? "Unknown URL")."

        case .clientError(let response):
            errorMessage = "A client error occurred with status code \(response.statusCode): \(self.localizedDescription)."

        case .serverError(let response):
            errorMessage = "A server error occurred with status code \(response.statusCode): \(self.localizedDescription)."

        case .decoding(error: let error):
            errorMessage = "A decoding error occurred: \(error.localizedDescription). Check the data format."

        case .unknown(message: let message):
            errorMessage = "An unknown error occurred with the message: \(message)."
        }
        
        return errorMessage
    }
}

struct HTTPResponse<T> {
    let value: T
    let response: HTTPURLResponse

    func map<U>(_ transform: (T) -> U) -> HTTPResponse<U> {
        HTTPResponse<U>(value: transform(value), response: response)
    }
}

extension HTTPResponse {
    init(_ tuple: (T?, URLResponse?, Error?)) throws {
        if let error = tuple.2{
            throw NetworkError.network(error: error)
        }else{
            guard let httpResponse = tuple.1 as? HTTPURLResponse, let value = tuple.0 else {
                throw NetworkError.invalidResponse(tuple.1)
            }
            self.value = value
            self.response = httpResponse
        }
    }
}

extension HTTPResponse {
    
    func validate() throws -> Self {
        switch response.statusCode {
        // Informational
        case (100..<200): return self
        // Success
        case (200..<300): return self
        // Redirection
        case (300..<400): return self
        // Client Error
        case (400..<500): throw NetworkError.clientError(response)
        // Server Error
        case (500..<600): throw NetworkError.serverError(response)
        default: throw NetworkError.unknown(message: "Unrecognized status code: \(response.statusCode)")
        }
    }
    
    // Decode method for when T is Data
    func decode<S: Decodable>(with decoder: JSONDecoder = .init()) throws -> S {
        guard let data = value as? Data else {
            throw NetworkError.decoding(error: NSError(domain: "Expected value to be of type Data.", code: 1001))
        }
        return try decoder.decode(S.self, from: data)
    }
}

 extension URLSession {
     func dataTaskPublisher(for request: Request) -> AnyPublisher<HTTPResponse<Data>, NetworkError> {
         dataTaskPublisher(for: request.asURLRequest())
             .tryMap { data, response -> HTTPResponse<Data> in
                 guard let httpResponse = response as? HTTPURLResponse else {
                     throw NetworkError.invalidResponse(response)
                 }
                 return HTTPResponse(value: data, response: httpResponse)
             }
             .mapError { NetworkError.wrap($0) }
             .eraseToAnyPublisher()
     }
 }
