#if canImport(Foundation)

import Foundation
@testable import AppsPlusData

public class MockSecureStorage: SecureStorage, @unchecked Sendable {
    
    public var setStrings = [SecureStorageKey: String?]()
    public var removedKeys = [SecureStorageKey]()
    public var returnCodables = [SecureStorageKey: Any]()
    private var setCodables = [SecureStorageKey: Any]()
    
    public init() {
        
    }
    
    public func setString(_ item: String?, forKey key: SecureStorageKey) throws {
        setStrings[key] = item
    }
    
    public func setCodable<E: Encodable>(for key: SecureStorageKey) -> E? {
        setCodables[key] as? E
    }
    
    public func string(forKey key: SecureStorageKey) -> String? {
        returnCodables[key] as? String
    }
    
    public func remove(key: SecureStorageKey) {
        removedKeys.append(key)
    }
    
    public func setValue<E>(_ value: E, forKey key: SecureStorageKey) where E : Encodable {
        setCodables[key] = value
    }
    
    public func value<D>(forKey key: SecureStorageKey) -> D? where D : Decodable {
        returnCodables[key] as? D
    }
}

#endif
