//
//  Bool+Utils.swift
//
//  Created by Mathew Gacy on 2/17/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

extension Bool {
    var smallInt: Int {
        self ? 1 : 0
    }

    var smallIntString: String {
        self ? "1" : "0"
    }

    static func random(probability: Double) -> Self {
        
        var prob = probability
        
        if CommandLine.arguments.contains("-FullSampleRate") {
            prob = 1.0
        }
        
        guard prob <= 1.0 else {
            return true
        }
        return Double.random(in: 0...1) <= prob
    }

    init?(_ int: Int) {
        switch int {
        case 0:
            self = false
        case 1:
            self = true
        default:
            return nil
        }
    }
}
