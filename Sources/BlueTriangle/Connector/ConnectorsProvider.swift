//
//  BTTConnectors.swift
//  
//
//  Created by Ashok Singh on 14/02/25.
//

protocol ConnectorsProviderProtocol {
    func getConnectors()-> [ConnectorProtocol]
}

class ConnectorsProvider : ConnectorsProviderProtocol{
   
    private var connectors : [ConnectorProtocol] = [ConnectorProtocol]()
    
    init(_ logger : Logging) {
#if canImport(Clarity)
        let connector = ClarityConnector(logger)
        connectors.append(connector)
#endif
    }
    
    func getConnectors() -> [ConnectorProtocol] {
        return connectors
    }
}

