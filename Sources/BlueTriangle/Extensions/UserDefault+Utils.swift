
//
//  UserDefault+Utils.swift
//
//  Created by JP on 18/07/23.
//  Copyright © 2023 Blue Triangle. All rights reserved.
//

import Foundation

final class UserDefaultsUtility {
    
    static func setData<T>(value: T, key: UserDefaultKeys) {
        
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
        
    }
    
    static func getData<T>(type: T.Type, forKey: UserDefaultKeys) -> T? {
        
        let defaults = UserDefaults.standard
        let value = defaults.object(forKey: forKey.rawValue) as? T
        return value
    }
    
    static func removeData(key: UserDefaultKeys) {
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    static func removeAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    static func saveCodable<T: Codable>(_ value: T, key: UserDefaultKeys) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        setData(value: data, key: key)
    }

    static func loadCodable<T: Codable>(_ type: T.Type, key: UserDefaultKeys) -> T? {
        guard let data = getData(type: Data.self, forKey: key) else { return nil }
        guard let value = try? JSONDecoder().decode(T.self, from: data) else {
            removeData(key: key)
            return nil
        }
        return value
    }

    enum UserDefaultKeys: String {
        case savedTimers
        case currentTimerDetail
        case pendingCrashRecord
        case pendingFatalErrorRecord
    }
}
