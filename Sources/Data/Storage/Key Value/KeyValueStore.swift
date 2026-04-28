#if canImport(Foundation)

import Foundation

public protocol KeyValueStore: Sendable {
    func set(_ value: Any?, forKey defaultName: String)
    func string(forKey defaultName: String) -> String?
    
    func data(forKey defaultName: String) -> Data?
    func removeObject(forKey key: String)
    
}

extension UserDefaults: KeyValueStore {}

#endif
