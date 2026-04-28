#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine
@testable import AppsPlusData

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class MockPersistentStorage: PersistentStorage, @unchecked Sendable {
    
    public enum StorageError: Error {
        case failedToFetch
        case failedToUpdate
        case failedToDelete
        case failedToSave
    }
    
    let identifier: String = "MockPersistentStorage.Identifier"
    public var fetchResults: AnyPublisher<Any, Error> = Fail(error: StorageError.failedToFetch).eraseToAnyPublisher()
    public var createResult: AnyPublisher<Void, Error> = Fail(error: StorageError.failedToUpdate).eraseToAnyPublisher()
    public var updateResult: AnyPublisher<Void, Error> = Fail(error: StorageError.failedToUpdate).eraseToAnyPublisher()
    public var deleteResult: AnyPublisher<Void, Error> = Fail(error: StorageError.failedToDelete).eraseToAnyPublisher()
    public var saveCalledCount = 0
    public var saveResult: AnyPublisher<Void, Error>?
    
    fileprivate var fetchRequests = [Any]()
    fileprivate var updateRequests = [Any]()
    fileprivate var deleteRequests = [Any]()
    fileprivate var storedEntities = [Any]()
    fileprivate var storedTransactions = [Any]()
    public var transactions = [PersistentStoreTransaction]()
    
    public init() {
        
    }
    
    public func entity<T>(_ type: T.Type) -> AnyAsynchronousEntity<T> {
        let entity = MockAsynchronousEntity<T>(parent: self).eraseToAnyEntity()
        storedEntities.append(entity)
        return entity
    }
    
    public func beginTransactions() -> PersistentStoreTransaction {
        let transaction = PersistentStoreTransaction { [weak self] in
            self?.transactions.append($0)
            return self?
                .updateResult
                .compactMap { [weak self] in
                    guard let self = self else {
                        return nil
                    }
                    return MockPersistentStoreUpdate(parent: self)
                }
                .eraseToAnyPublisher() ?? Fail(error: StorageError.failedToUpdate).eraseToAnyPublisher()
        }
        storedTransactions.append(transaction)
        return transaction
    }
    
    public func fetchRequests<Entity>(for entity: Entity.Type) -> [AsynchronousFetchRequest<Entity>] {
        fetchRequests.compactMap { $0 as? AsynchronousFetchRequest<Entity> }
    }
    
    public func updateRequests<Entity>(for entity: Entity.Type) -> [AsynchronousUpdateRequest<Entity>] {
        updateRequests.compactMap { $0 as? AsynchronousUpdateRequest<Entity> }
    }
    
    public func deleteRequests<Entity>(for entity: Entity.Type) -> [AsynchronousDeleteRequest<Entity>] {
        deleteRequests.compactMap { $0 as? AsynchronousDeleteRequest<Entity> }
    }
    
    public func save() -> AnyPublisher<Void, Error> {
        saveCalledCount += 1
        return saveResult ?? Fail(error: StorageError.failedToSave).eraseToAnyPublisher()
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class MockPersistentStoreUpdate: PersistentStoreUpdate, @unchecked Sendable {
    
    public let parent: MockPersistentStorage
    public var identifier: String {
        parent.identifier
    }
    
    public init(parent: MockPersistentStorage) {
        self.parent = parent
    }
    
    public func commit() -> AnyPublisher<Void, Error> {
        parent.save()
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class MockAsynchronousEntity<EntityType>: AsynchronousEntity, @unchecked Sendable {
    
    public let parent: MockPersistentStorage
    
    public init(parent: MockPersistentStorage) {
        self.parent = parent
    }
    
    public func fetch() -> AsynchronousFetchRequest<EntityType> {
        AsynchronousFetchRequest(publisher: { [weak self] request in
            guard let self = self else {
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            self.parent.fetchRequests.append(request)
            return self.parent.fetchResults
                .compactMap { ($0 as? [Any])?.compactMap { $0 as? EntityType } }
                .eraseToAnyPublisher()
        }, fetchRequest: .empty())
    }
    
    public func create() -> AsynchronousUpdateRequest<EntityType> {
        AsynchronousUpdateRequest(publisher: { [weak self] request in
            guard let self = self else {
                return Fail(error: MockPersistentStorage.StorageError.failedToUpdate).eraseToAnyPublisher()
            }
            self.parent.updateRequests.append(request)
            return self.parent.updateResult
                .map { MockPersistentStoreUpdate(parent: self.parent) }
                .eraseToAnyPublisher()
        }, fetchRequest: .create())
    }
    
    public func update(orCreate: Bool) -> AsynchronousUpdateRequest<EntityType> {
        AsynchronousUpdateRequest(publisher: { [weak self] request in
            guard let self = self else {
                return Fail(error: MockPersistentStorage.StorageError.failedToUpdate).eraseToAnyPublisher()
            }
            self.parent.updateRequests.append(request)
            return self.parent.updateResult
                .map { MockPersistentStoreUpdate(parent: self.parent) }
                .eraseToAnyPublisher()
        }, fetchRequest: .update(orCreate: orCreate))
    }
    
    public func delete() -> AsynchronousDeleteRequest<EntityType> {
        AsynchronousDeleteRequest(publisher: { [weak self] request in
            guard let self = self else {
                return Fail(error: MockPersistentStorage.StorageError.failedToDelete).eraseToAnyPublisher()
            }
            self.parent.deleteRequests.append(request)
            return self.parent.deleteResult
                .map { MockPersistentStoreUpdate(parent: self.parent) }
                .eraseToAnyPublisher()
        }, fetchRequest: .empty())
    }
    
}


#endif
