#if canImport(Foundation)

import Foundation

public struct SecureStorageImpl: SecureStorage, @unchecked Sendable {
    
    private let keychain: KeychainAccess
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(keychain: KeychainAccess, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.keychain = keychain
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public func setString(_ item: String?, forKey key: SecureStorageKey) throws {
        if let item = item {
            try keychain.set(item, key: key.rawValue, ignoringAttributeSynchronizable: true)
        } else {
            removeItem(with: key)
        }
    }
    
    public func setValue<Item: Codable>(_ item: Item?, forKey key: SecureStorageKey) throws {
        if let item = item {
            let encodedValue = try encoder.encode(item)
            try keychain.set(encodedValue, key: key.rawValue, ignoringAttributeSynchronizable: true)
        } else {
            removeItem(with: key)
        }
    }
    
    public func string(forKey key: SecureStorageKey) -> String? {
        return try? keychain.get(key.rawValue, ignoringAttributeSynchronizable: true)
    }
    
    public func value<Item: Codable>(forKey key: SecureStorageKey) -> Item? {
        guard let data = try? keychain.getData(key.rawValue, ignoringAttributeSynchronizable: true) else {
            return nil
        }
        
        return try? decoder.decode(Item.self, from: data)
    }
    
    private func removeItem(with key: SecureStorageKey) {
        try? keychain.remove(key.rawValue, ignoringAttributeSynchronizable: true)
    }
    
}

#endif
