//
//  NetworkCaptureTracker.swift
//
//  Created by Ashok Singh on 09/11/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

public class NetworkCaptureTracker {
    private let url: String
    private let method: String
    private let requestBodylength: Int64
    private var timer : InternalTimer
    
    public init(url: String, method : String, requestBodylength : Int64) {
        self.url = url
        self.method = method
        self.requestBodylength = requestBodylength
        self.timer = InternalTimer(logger: BTLogger())
        self.timer.start()
    }
    
    
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
    let method: String
    let contentType: String
    let httpStatusCode: Int64?
    let requestBodylength: Int64
    let responseBodyLength: Int64
    let error: Error?
}
