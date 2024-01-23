//
//  File.swift
//
//  Created by Mathew Gacy on 7/3/22.
//  Copyright © 2022 Blue Triangle. All rights reserved.
//

import Foundation

struct File {
    let directory: URL
    let name: String

    var url: URL {
        directory.appendingPathComponent(name)
    }

    var path: String {
        url.path
    }

    init(directory: URL, name: String) {
        self.directory = directory
        self.name = name
    }

    init?(fileLocation: FileLocation, name: String) {
        guard let containerURL = fileLocation.containerURL else {
            return nil
        }
        self.directory = containerURL
        self.name = name
    }
}

extension File {
    static let crashReport = Self(fileLocation: UserLocation.cache(Constants.persistenceDirectory), name: "crash_report")
    static let requests = Self(fileLocation: UserLocation.cache(Constants.persistenceDirectory), name: "requests")
    
    static let cacheRequestsFolder = Self(fileLocation: UserLocation.cache(Constants.cacheRequestsDirectory), name: "")
    static func cacheRequests(_ fileName : String) -> File?{
        let file = fileName.contains(".json") ? fileName : "\(fileName).json"
        return Self(fileLocation: UserLocation.cache(Constants.cacheRequestsDirectory), name: file)
    }
}
