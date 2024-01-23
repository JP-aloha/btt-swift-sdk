//
//  RequestFailureHandling.swift
//
//  Created by Mathew Gacy on 7/17/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Combine
import Foundation
import Network

protocol RequestFailureHandling: AnyObject {
    var send: (() -> Void)? { get set }

    func configureSubscriptions(queue: DispatchQueue)
    func store(request: Request)
    func sendSaved()
}
