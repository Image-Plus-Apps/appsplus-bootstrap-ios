#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct AsynchronousUpdateRequest<T>: AsynchronousPersistentStoreRequest, @unchecked Sendable {
    
    public typealias Entity = T
    public typealias Output = PersistentStoreUpdate
    
    let publisher: PublisherType
    let fetchRequest: UpdateRequest<T>
    
    public init(publisher: @escaping (Self) -> AnyPublisher<Output, Error>, fetchRequest: UpdateRequest<T>) {
        self.publisher = publisher
        self.fetchRequest = fetchRequest
    }
    
    var shouldUpdate: Bool {
        fetchRequest.shouldUpdate
    }
    
    var shouldCreate: Bool {
        fetchRequest.shouldCreate
    }
    
    var prevalidator: ((T, SynchronousStorage) -> Bool)? {
        fetchRequest.prevalidator
    }
    
    var modifier: ((T, SynchronousStorage) -> Void)? {
        fetchRequest.modifier
    }
    
    public func sorted<Value>(by keyPath: KeyPath<T, Value>, ascending: Bool) -> AsynchronousUpdateRequest {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.sorted(by: keyPath, ascending: ascending))
    }
    
    public func limit(_ limit: Int) -> AsynchronousUpdateRequest {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.limit(limit))
    }
    
    public func offset(_ offset: Int) -> AsynchronousUpdateRequest {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.offset(offset))
    }
    
    public func batchSize(_ batchSize: Int) -> AsynchronousUpdateRequest {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.batchSize(batchSize))
    }
    
    public func suchThat(predicate: NSPredicate) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.suchThat(predicate: predicate))
    }
    
    public func and(predicate: NSPredicate) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.and(predicate: predicate))
    }
    
    public func or(predicate: NSPredicate) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.or(predicate: predicate))
    }
    
    public func excluding(predicate: NSPredicate) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.excluding(predicate: predicate))
    }
    
    public func prevalidate(_ validation: @escaping (T, SynchronousStorage) -> Bool) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.prevalidate(validation))
    }
    
    public func prevalidate(_ validation: @escaping (T) -> Bool) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.prevalidate(validation))
    }
    
    public func prevalidate(_ validation: @escaping () -> Bool) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.prevalidate(validation))
    }
    
    public func modify(_ modifier: @escaping (T, SynchronousStorage) -> Void) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.modify(modifier))
    }
    
    public func modify(_ modifier: @escaping (T) -> Void) -> AsynchronousUpdateRequest<T> {
        AsynchronousUpdateRequest(publisher: publisher, fetchRequest: fetchRequest.modify(modifier))
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousUpdateRequest: PersistentStoreRequest {
    
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
extension AsynchronousUpdateRequest: FilterRequest { }

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousUpdateRequest {
    
    public func perform() -> AnyPublisher<Output, Error> {
        publisher(self)
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousUpdateRequest: Equatable {
    
    public static func == (lhs: AsynchronousUpdateRequest, rhs: AsynchronousUpdateRequest) -> Bool {
        lhs.limit == rhs.limit &&
            lhs.offset == rhs.offset &&
            lhs.batchSize == rhs.batchSize &&
            lhs.predicate == rhs.predicate &&
            lhs.sortDescriptors == rhs.sortDescriptors &&
            lhs.shouldUpdate == rhs.shouldUpdate &&
            lhs.shouldCreate == rhs.shouldCreate
    }
    
}

#endif
