
import Foundation

final class UserDefaultsUtility {
    
    static func setData<T>(value: T, key: UserDefaultKeys) {
        
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key.rawValue)
        
    }
    
    static func getData<T>(type: T.Type, forKey: UserDefaultKeys) -> T? {
        
        let defaults = UserDefaults.standard
        let value = defaults.object(forKey: forKey.rawValue) as? T
        return value
    }
    
    static func removeData(key: UserDefaultKeys) {
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: key.rawValue)
    }
    
    static func removeAll() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
    enum UserDefaultKeys: String {
        case currentPage
        case startTime
        case sessionId
        
    }
}
