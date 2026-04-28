#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol PersistentStorage: Sendable {
    
    func entity<T>(_ type: T.Type) -> AnyAsynchronousEntity<T>
    func beginTransactions() -> PersistentStoreTransaction
}

#endif
