#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct PersistentStoreTransaction: @unchecked Sendable {
    
    typealias PublisherType = (PersistentStoreTransaction) -> AnyPublisher<PersistentStoreUpdate, Error>
    public typealias Transaction = (SynchronousStorage) throws -> Void
    
    let publisher: PublisherType
    let transactions: Transaction?
    
    init(publisher: @escaping PublisherType) {
        self.publisher = publisher
        self.transactions = nil
    }
    
    private init(publisher: @escaping PublisherType, transactions: Transaction?) {
        self.publisher = publisher
        self.transactions = transactions
    }
    
    public func addTransaction(_ transaction: @escaping Transaction) -> PersistentStoreTransaction {
        PersistentStoreTransaction(publisher: publisher) {
            try transactions?($0)
            try transaction($0)
        }
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension PersistentStoreTransaction {
    
    public func perform() -> AnyPublisher<PersistentStoreUpdate, Error> {
        publisher(self)
    }
    
}

#endif
