#if canImport(Foundation)

import Foundation

public protocol KeychainAccess {
    func set(_ value: String, key: String, ignoringAttributeSynchronizable: Bool) throws
    func set(_ value: Data, key: String, ignoringAttributeSynchronizable: Bool) throws
    
    func get(_ key: String, ignoringAttributeSynchronizable: Bool) throws -> String?
    func getData(_ key: String, ignoringAttributeSynchronizable: Bool) throws -> Data?
    
    func remove(_ key: String, ignoringAttributeSynchronizable: Bool) throws
}

#endif
