//
//  ConnectorCustomVariableHandler.swift
//  
//
//
//  Created by JP on 28/02/25.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

protocol CustomVariableAdapterProtocol {
    func setConnectorCustomVariable(value: String?, forKey key: String)
    func clearConnectorCustomVariable(forKey key: String)
}

final class CustomVariableAdapter : CustomVariableAdapterProtocol{
    
    func setConnectorCustomVariable(value: String?, forKey key: String) {
        if let value = value{
            BlueTriangle.setCustomVariable(key, value: value)
        }
    }
    
    func clearConnectorCustomVariable(forKey key: String) {
        BlueTriangle.clearCustomVariable(key)
    }
}

