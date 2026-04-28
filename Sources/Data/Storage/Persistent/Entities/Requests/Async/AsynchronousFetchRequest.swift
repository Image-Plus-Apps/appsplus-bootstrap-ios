#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct AsynchronousFetchRequest<T>: AsynchronousPersistentStoreRequest, @unchecked Sendable {
    
    public typealias Entity = T
    public typealias Output = [T]
    
    let publisher: PublisherType
    let fetchRequest: FetchRequest<T>
    let shouldSubscribe: Bool
    
    public init(publisher: @escaping (Self) -> AnyPublisher<Output, Error>, fetchRequest: FetchRequest<T>) {
        self.init(publisher: publisher, fetchRequest: fetchRequest, shouldSubscribe: false)
    }
    
    private init(publisher: @escaping PublisherType, fetchRequest: FetchRequest<T>, shouldSubscribe: Bool) {
        self.publisher = publisher
        self.fetchRequest = fetchRequest
        self.shouldSubscribe = shouldSubscribe
    }
    
    public func sorted<Value>(by keyPath: KeyPath<T, Value>, ascending: Bool) -> AsynchronousFetchRequest {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.sorted(by: keyPath, ascending: ascending))
    }
    
    public func suchThat(predicate: NSPredicate) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.suchThat(predicate: predicate))
    }
    
    public func and(predicate: NSPredicate) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.and(predicate: predicate))
    }
    
    public func or(predicate: NSPredicate) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.or(predicate: predicate))
    }
    
    public func excluding(predicate: NSPredicate) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.excluding(predicate: predicate))
    }
    
    public func limit(_ limit: Int) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.limit(limit))
    }
    
    public func offset(_ offset: Int) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.offset(offset))
    }
    
    public func batchSize(_ batchSize: Int) -> AsynchronousFetchRequest<T> {
        AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest.batchSize(batchSize))
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousFetchRequest: PersistentStoreRequest {
    
    var limit: Int? {
        fetchRequest.limit
    }
    
    var predicate: NSPredicate? {
        fetchRequest.predicate
    }
    
    var offset: Int? {
        fetchRequest.offset
    }
    
    var batchSize: Int? {
        fetchRequest.batchSize
    }
    
    var sortDescriptors: [NSSortDescriptor]? {
        fetchRequest.sortDescriptors
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousFetchRequest: FilterRequest { }

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousFetchRequest {
    
    public func perform() -> AnyPublisher<Output, Error> {
        publisher(AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest, shouldSubscribe: false))
    }
    
    public func subscribe() -> AnyPublisher<Output, Error> {
        publisher(AsynchronousFetchRequest(publisher: publisher, fetchRequest: fetchRequest, shouldSubscribe: true))
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousFetchRequest: Equatable {
    
    public static func == (lhs: AsynchronousFetchRequest, rhs: AsynchronousFetchRequest) -> Bool {
        lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.batchSize == rhs.batchSize &&
            lhs.predicate == rhs.predicate &&
            lhs.sortDescriptors == rhs.sortDescriptors
    }
    
}

#endif
