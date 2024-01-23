//
//  PayloadCache.swift
//
//
//  Created by Ashok Singh on 23/11/23.
//

import UIKit


protocol PayloadCacheProtocol: AnyObject {
    //var memoryLimit: UInt { get set }
    //var expiryDuration : Millisecond { get set }
    func pickNext() throws -> Payload?
    func save(_ payload : Payload) throws
    func delete(_ payload : Payload) throws
}

class PayloadCache : PayloadCacheProtocol{
   
    //MB * 1024 * 1024
    private(set) var memoryLimit: UInt
    //day * 24 * 60 * 60 * 1000
    private(set) var expiryDuration : Millisecond
    
    private var minExpiryDuration : Millisecond =  2 * 60 * 1000//1 * 24 * 60 * 60 * 1000
    private var maxExpiryDuration : Millisecond = 10 * 24 * 60 * 60 * 1000
    private var minMemoryLimit : UInt =   5 * 1024 //10 * 1024 * 1024
    private var maxMemoryLimit : UInt = 300 * 1024 * 1024
       
    init(_ memoryLimit : UInt , expiry : Millisecond){
        
        if memoryLimit < minMemoryLimit{
            self.memoryLimit = minMemoryLimit
        }
        else if(memoryLimit > maxMemoryLimit){
            self.memoryLimit = maxMemoryLimit
        }
        else{
            self.memoryLimit = memoryLimit
        }
        
        if expiry < minExpiryDuration{
            self.expiryDuration = minExpiryDuration
        }
        else if(expiry > maxExpiryDuration){
            self.expiryDuration = maxExpiryDuration
        }
        else{
            self.expiryDuration = expiry
        }
    }
    
    // Return most recent of type by priority (Analytics, Error, Wcd) which are not expired and not attempted it all attempt.
    
    func pickNext() throws -> Payload?{
        
        if let file = try getNextPickFile(){
            return file
        }
        else{
            return nil
        }
    }
    
    /*
     Saved payload must be retrieved until expired.
     If saving this exceeds memory limit should remove by following criteria:
     i. Expired
     ii. Oldest Analytics and Wcd records
     iii. Oldest Error
     */
    func save(_ payload : Payload) throws {
        try payload.serialize()
        try self.clearCache()
    }
    
    func delete(_ payload : Payload) throws  {
        try payload.delete()
    }
}


extension PayloadCache {
 
    private func clearCache() throws{
       
        while try isOverSize() {
            if let payload = try getRemovableFile(){
                try payload.delete()
            }else{
                break
            }
        }
    }
    
    private func isOverSize() throws -> Bool{

        var folderSize: UInt64 = 0
        let files = try self.getAllAvailableFiles()
        
        for file in files {
            guard let newfile = File.cacheRequests(file) else { return false}
            let attr = try FileManager.default.attributesOfItem(atPath: newfile.path)
            let fileSize = attr[FileAttributeKey.size] as! UInt64
            folderSize = folderSize + fileSize
        }
        
        if folderSize > memoryLimit{
            return true
        }
        
        return false
    }
    
    private func getRemovableFile() throws -> Payload?{
                
        let payloads = try getAllCachePayload()
        
        //Expired Attempts
        let expiredAttempeds = payloads.filter({ payload in
            return payload.payloadAttempts >= Constants.maxPayloadAttempts
        })
        
        if let file = expiredAttempeds.first {
            return file
        }
       
        //Expired
        let expired = payloads.filter { payload in
            return hasExpired(payload)
        }
        
        if let file = expired.first {
            return file
        }
        
        //Analitics
        let analitics = payloads.filter { payload in
            return payload.type.contains(PayloadType.ANALITICS.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = analitics.first {
            return file
        }
        
        //WCDs
        let wcds = payloads.filter { payload in
            return payload.type.contains(PayloadType.WCD.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = wcds.first {
            return file
        }
        
        //Errors
        let errors = payloads.filter { payload in
            return payload.type.contains(PayloadType.ERROR.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = errors.first {
            return file
        }
        
        return nil
    }
    
    private func getNextPickFile() throws -> Payload?{
                
        let payloads = try getAllCachePayload()
        
        //Expired Attempts
        let filteredPayloads = payloads.filter({ payload in
            return payload.payloadAttempts < Constants.maxPayloadAttempts
        }).filter { payload in
            return !hasExpired(payload)
        }
        
        //Analitics
        let analitics = filteredPayloads.filter { payload in
            return payload.type.contains(PayloadType.ANALITICS.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = analitics.first {
            return file
        }
        
        //Errors
        let errors = filteredPayloads.filter { payload in
            return payload.type.contains(PayloadType.ERROR.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = errors.first {
            return file
        }
        
        //WCDs
        let wcds = filteredPayloads.filter { payload in
            return payload.type.contains(PayloadType.WCD.rawValue)
        }.sorted { payload1, payload2 in
            return payload1.createdDate < payload2.createdDate
        }
        
        if let file = wcds.first {
            return file
        }
        
        return nil
    }
    
    private  func getAllCachePayload() throws -> [Payload]{
        
        var payloads = [Payload]()
        
        let files = try self.getAllAvailableFiles()
        
        for file in files {
            guard let newfile = File.cacheRequests(file) else { return payloads}
            let payload = try Payload.deserialize(newfile)
            payloads.append(payload)
            
        }
        
        return payloads
    }
    
    private  func getAllAvailableFiles() throws -> [String]{
        
        var fileList = [String]()
        
        guard let docs = File.cacheRequestsFolder?.url.path else { return fileList}
       
        if let files = try? FileManager.default.contentsOfDirectory(atPath:docs).filter({ name in return name.contains(".json")}) {
            fileList.append(contentsOf: files)
        }
        
        return fileList
    }
    
    private func hasExpired(_ payload : Payload) -> Bool{
        if (Date().timeIntervalSince1970 - payload.createdDate.timeIntervalSince1970).milliseconds > expiryDuration{
            return true
        }
        return false
    }
    
}
