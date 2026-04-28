#if canImport(Foundation)

import Foundation
@testable import AppsPlusData

public class MockKeyValueStorage: KeyValueStorage, @unchecked Sendable {
    
    public var setStrings = [KeyValueStorageKey: String?]()
    public var removedKeys = [KeyValueStorageKey]()
    public var returnCodables = [KeyValueStorageKey: Any]()
    private var setCodables = [KeyValueStorageKey: Any]()
    
    public init() {
        
    }
    
    public func setCodable<E: Encodable>(for key: KeyValueStorageKey) -> E? {
        setCodables[key] as? E
    }
    
    public func set(_ value: String?, forKey key: KeyValueStorageKey) {
        setStrings[key] = value
    }
    
    public func string(forKey key: KeyValueStorageKey) -> String? {
        returnCodables[key] as? String
    }
    
    public func remove(key: KeyValueStorageKey) {
        removedKeys.append(key)
    }
    
    public func setValue<E>(_ value: E, forKey key: KeyValueStorageKey) where E : Encodable {
        setCodables[key] = value
    }
    
    public func value<D>(forKey key: KeyValueStorageKey) -> D? where D : Decodable {
        returnCodables[key] as? D
    }
}

#endif
