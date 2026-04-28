#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol PersistentStoreUpdate: Sendable {
    var identifier: String { get }
    func commit() -> AnyPublisher<Void, Error>
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct PersistentStoreUpdateSkip: PersistentStoreUpdate, Sendable {
    public let identifier: String = "PersistentStoreUpdate.Skip"
    public func commit() -> AnyPublisher<Void, Error> {
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public init() {}
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension Publisher where Output == PersistentStoreUpdate {
    
    public func save() -> AnyPublisher<Void, Error> {
        reduce([PersistentStoreUpdate]()) { current, value in
            if current.contains(where: { $0.identifier == value.identifier }) {
                return current
            }
            return current + [value]
        }
        .mapError { $0 as Error }
        .flatMap { $0.publisher.setFailureType(to: Error.self) }
        .flatMap { $0.commit() }
        .eraseToAnyPublisher()
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension Publisher where Output: PersistentStoreUpdate {
    
    public func save() -> AnyPublisher<Void, Error> {
        map { $0 as PersistentStoreUpdate }
            .save()
    }
    
}

#endif
