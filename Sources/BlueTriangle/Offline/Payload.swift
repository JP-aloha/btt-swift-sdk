//
//  Payload.swift
//
//
//  Created by Ashok Singh on 23/11/23.
//

import UIKit

class Payload : Codable{

    private(set) var payloadAttempts: Int = 0
    private(set) var url : URL
    private(set) var id : String
    private(set) var data : Request
    private(set) var type : String
    private(set) var createdDate : Date
    
    init(request: Request) {
        self.id = "\(Payload.fileType(request.url).rawValue)_\(Identifier.random())"
        self.url = request.url
        self.type = Payload.fileType(url).rawValue
        self.data = request
        self.createdDate = Date()
    }
    
    func serialize() throws {
        self.payloadAttempts = self.payloadAttempts + 1
        if let encodedData = try? JSONEncoder().encode(self), let file = File.cacheRequests(self.id) {
            if !FileManager.default.fileExists(atPath: file.directory.absoluteString){
                try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
            }
            try encodedData.write(to: file.url, options: .atomic)
        }
    }
    
    static func deserialize(_ file:  File) throws -> Payload{
        let data  = try Data(contentsOf: file.url)
        let payload  = try JSONDecoder().decode(Payload.self, from: data)
        return payload
    }
    
    func delete() throws {
        guard let newfile = File.cacheRequests(id) else { return}
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: newfile.path){
            try fileManager.removeItem(at: newfile.url)
        }
    }
    
    private static func fileType(_ url : URL)-> PayloadType{
        
        if url.path.contains("err.rcv"){
            return .ERROR
        }
        else if url.path.contains("wcd.rcb"){
            return .WCD
        }
        else{
            return .ANALITICS
        }
    }
}


public enum PayloadType : String{
    case ANALITICS
    case WCD
    case ERROR
}
