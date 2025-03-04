import Foundation
class ConfigurationManager {
    static let singleton = ConfigurationManager()

    private let defaults = UserDefaults.standard
    
    
    private init() {
        
        if anonymousId == nil {
            anonymousId = UUID().uuidString
        }
    }
    
    var anonymousId: String? {
        get { return defaults.value(forKey: "anonymousId") as? String }
        set { defaults.set(newValue, forKey: "anonymousId") }
    }
    
}
