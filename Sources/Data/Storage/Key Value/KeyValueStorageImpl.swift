#if canImport(Foundation)

import Foundation

public struct KeyValueStorageImpl: KeyValueStorage, @unchecked Sendable {
    
    private let keyValueStore: KeyValueStore
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(keyValueStore: KeyValueStore, encoder: JSONEncoder, decoder: JSONDecoder) {
        self.keyValueStore = keyValueStore
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public func set(_ value: String?, forKey key: KeyValueStorageKey) {
        keyValueStore.set(value, forKey: key.rawValue)
    }
    
    public func string(forKey key: KeyValueStorageKey) -> String? {
        keyValueStore.string(forKey: key.rawValue)
    }
    
    public func setValue<E>(_ value: E, forKey key: KeyValueStorageKey) where E : Encodable {
        keyValueStore.set(try? encoder.encode(value), forKey: key.rawValue)
    }
    
    public func value<D>(forKey key: KeyValueStorageKey) -> D? where D : Decodable {
        keyValueStore.data(forKey: key.rawValue).flatMap {
            try? decoder.decode(D.self, from: $0)
        }
    }
    
    public func remove(key: KeyValueStorageKey) {
        keyValueStore.removeObject(forKey: key.rawValue)
    }
}

#endif
