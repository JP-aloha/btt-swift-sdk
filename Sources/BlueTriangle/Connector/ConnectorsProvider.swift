//
//  BTTConnectors.swift
//  
//
//  Created by JP on 13/02/25.
//  Copyright © 2023 Blue Triangle. All rights reserved.

protocol ConnectorsProviderProtocol {
    func getConnectors()-> [ConnectorProtocol]
}

class ConnectorsProvider : ConnectorsProviderProtocol{
   
    private var connectors : [ConnectorProtocol] = [ConnectorProtocol]()
    
    init(_ logger: Logging, cvAdapter: CustomVariableAdapterProtocol) {
#if canImport(Clarity)
        let connector = ClarityConnector(logger, cvAdapter: cvAdapter)
        connectors.append(connector)
#endif
    }
    
    func getConnectors() -> [ConnectorProtocol] {
        return connectors
    }
}

