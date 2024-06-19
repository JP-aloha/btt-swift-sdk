//
//  TimerRequestBuilder.swift
//
//  Created by Mathew Gacy on 6/15/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct TimerRequestBuilder {
    let builder: (Session, BTTimer, PurchaseConfirmation?) throws -> Request

    static let live = TimerRequestBuilder { session, timer, purchase in
        let model = TimerRequest(session: session,
                                 page: timer.page,
                                 timer: timer.pageTimeInterval,
                                 purchaseConfirmation: purchase,
                                 performanceReport: timer.performanceReport,
                                 nativeAppProperties : timer.nativeAppProperties)
        return try Request(method: .post,
                           url: Constants.timerEndpoint,
                           headers: nil,
                           model: model,
                           encode: {
            try requestEncoder.encode($0).base64EncodedData()
            
        })
    }
    
    static let requestEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
}
