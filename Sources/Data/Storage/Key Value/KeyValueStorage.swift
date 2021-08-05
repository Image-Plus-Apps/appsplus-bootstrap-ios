#if canImport(Foundation)

import Foundation

public struct KeyValueStorageKey {
    let rawValue: String
    
    public init(value: String) {
        self.rawValue = value
    }
}

extension KeyValueStorageKey: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}

protocol KeyValueStorage {
    func setValue<E: Encodable>(_ value: E, forKey key: KeyValueStorageKey)
    func value<D: Decodable>(forKey key: KeyValueStorageKey) -> D?
    
    func set(_ value: String?, forKey key: KeyValueStorageKey)
    func string(forKey key: KeyValueStorageKey) -> String?
    func remove(key: KeyValueStorageKey)
}

#endif
