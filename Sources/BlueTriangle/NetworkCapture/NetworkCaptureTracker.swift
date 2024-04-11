//
//  NetworkCaptureTracker.swift
//
//  Created by Ashok Singh on 09/11/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation


///This class is used to manually capture one HTTP request.
///
/// If the user has a url, method, and requestBodyLength in the request, and httpStatusCode, responseBodyLength, and contentType in the response, use the following methods to create and submit a capture request.
///
///       public init(url: String, method : String, requestBodylength : Int64)
///       public func submit(_ httpStatusCode: Int64, responseBodyLength : Int64, contentType : String)
///
/// If the user has only  URLRequest  in the request, and URLResponse in the response, use the following methods to create and submit a capture request.
///
///       public init(request: URLRequest)
///       public func submit(_ response : URLResponse)
///
/// If the user encounters an error during a network call, they can use the following methods to submit a failed capture request along with any constructor.
///
///       public func failled(_ error : Error)
///
///
///The class uses a timer to calculate the duration between the 'init' constructors and the 'submit' overloads, or between 'init' and 'failed' methods.
///

public class NetworkCaptureTracker {
    private let url: String
    private let method: String?
    private let requestBodylength: Int64
    
    ///This timer is used to calculate the duration
    private var timer : InternalTimer
    
    ///Creates and initializes a NetworkCaptureTracker with the given url, method and requestBodylength
    ///
    ///- Parameters:
    /// - url: The URL for the request.
    /// - method:  The Method used to create request.
    /// - requestBodylength:  The expected content length
    ///
    ///Constructor to create a capture request with the url, method, and requestBodyLength.
    public init(url: String, method : String, requestBodylength : Int64) {
        self.url = url
        self.method = method
        self.requestBodylength = requestBodylength
        self.timer = InternalTimer(logger: BTLogger())
        self.timer.start()
    }
    
    ///Creates and initializes a NetworkCaptureTracker with the given URLRequest
    ///
    ///- Parameters:
    /// - request :  The URLRequest for the request.
    ///
    ///Constructor to create a capture request with the urlRequest parameter.
    public init(request: URLRequest) {
        self.url = request.url?.absoluteString ?? ""
        self.method = request.httpMethod
        self.requestBodylength = Int64(request.httpBody?.count ?? 0)
        self.timer = InternalTimer(logger: BTLogger())
        self.timer.start()
    }
    ///Submit NetworkCapture with the given URLResponse
    ///
    ///- Parameters:
    /// - response : The URLResponse .
    ///
    ///Method to submit a capture request with urlRequest paramerer.
    public func submit(_ response : URLResponse){
        self.timer.end()
        BlueTriangle.captureRequest(timer: timer, response: response)
    }
    
    ///Submit NetworkCapture with the given HTTP status code, response body length, and content type.
    ///
    ///- Parameters:
    /// - httpStatusCode :  The status code of response .
    /// - responseBodyLength :  The expected response content length .
    /// - contentType :  The content type of the response.
    ///
    ///Method to submit a capture request with the parameters httpStatusCode, responseBodyLength, and contentType.
    ///
    public func submit(_ httpStatusCode: Int64, responseBodyLength : Int64, contentType : String){
        self.timer.end()
        BlueTriangle.captureRequest(timer: timer,
                                    response: CustomResponse(url: self.url,
                                                             method: self.method,
                                                          contentType: contentType,
                                                          httpStatusCode: httpStatusCode,
                                                             requestBodylength: self.requestBodylength,
                                                             responseBodyLength: responseBodyLength,
                                                             error: nil))
    }
    
    ///Submit a failed NetworkCapture with the reported Error.
    ///
    ///- Parameters:
    /// - error : The error reported .
    ///
    ///Method to submit a failed capture request with the error parameter.
    public func failled(_ error : Error){
        self.timer.end()
        BlueTriangle.captureRequest(timer: timer,
                                    response: CustomResponse(url: self.url,
                                                             method: self.method,
                                                          contentType: "",
                                                          httpStatusCode: 600,
                                                             requestBodylength: self.requestBodylength,
                                                             responseBodyLength: 0,
                                                             error: error))
    }
}

struct CustomResponse{
    let url: String
    let method: String?
    let contentType: String
    let httpStatusCode: Int64?
    let requestBodylength: Int64
    let responseBodyLength: Int64
    let error: Error?
}
