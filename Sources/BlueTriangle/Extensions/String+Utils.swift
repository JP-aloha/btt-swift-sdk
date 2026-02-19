//
//  String+Utils.swift
//  blue-triangle
//
//  Created by Ashok Singh on 12/02/26.
//

import Foundation

extension String {
    
    func matchesWildcard(_ pattern: String) -> Bool {
        let regexPattern = "^" + pattern.replacingOccurrences(of: "*", with: ".*") + "$"
        
        return self.range(
            of: regexPattern,
            options: [.regularExpression]
        ) != nil
    }
}
