#if canImport(Foundation)

import Foundation

public struct SecureStorageKey: Hashable, Sendable {
    public let rawValue: String
    
    public init(value: String) {
        self.rawValue = value
    }
}

extension SecureStorageKey: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}

public protocol SecureStorage: Sendable {
    func setString(_ item: String?, forKey key: SecureStorageKey) throws
    func setValue<Item: Codable>(_ item: Item?, forKey key: SecureStorageKey) throws
    
    func string(forKey key: SecureStorageKey) -> String?
    func value<Item: Codable>(forKey key: SecureStorageKey) -> Item?
}

#endif
