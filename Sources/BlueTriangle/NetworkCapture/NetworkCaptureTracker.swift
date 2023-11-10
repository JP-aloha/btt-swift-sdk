//
//  NetworkCaptureTracker.swift
//  
//  Created by Ashok Singh on 09/11/23
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import UIKit

public class NetworkCaptureTracker {
    private let url: String
    private let status: String
    private let length: Int64
    private var timer : InternalTimer
    
    public init(url: String, status : String, length : Int64) {
        self.url = url
        self.status = status
        self.length = length
        self.timer = InternalTimer(logger: BTLogger())
        self.timer.start()
    }
    
    public func submit(){
        self.timer.end()
        BlueTriangle.captureRequest(timer: timer,
                                 response: CustomResponse(url:self.url,
                                                             status: self.status,
                                                             length: self.length))
    }
}

struct CustomResponse{
    let url: String
    let status: String
    let length: Int64
}
