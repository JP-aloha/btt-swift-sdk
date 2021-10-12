//
//  Bundle+Utils.swift
//
//  Created by Mathew Gacy on 10/8/21.
//  Copyright © 2021 Blue Triangle. All rights reserved.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}
