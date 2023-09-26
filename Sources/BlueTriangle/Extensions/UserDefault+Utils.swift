
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
    
    enum UserDefaultKeys: String {
        
        case savedTimers
        case currentTimerDetail
    }
}
