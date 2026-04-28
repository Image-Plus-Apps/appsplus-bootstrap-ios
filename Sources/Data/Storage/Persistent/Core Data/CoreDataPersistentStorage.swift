#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
enum CoreDataPersistentStorageError: Error {
    case storeUnavailable
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class CoreDataPersistentStorage: PersistentStorage, @unchecked Sendable {
    
    let identifier = "CoreDataPersistentStorage.\(UUID().uuidString)"
    let container: CoreDataPersistentContainer
    
    public init(container: CoreDataPersistentContainer) {
        self.container = container
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

    public func entity<T>(_ type: T.Type) -> AnyAsynchronousEntity<T> {
        AsynchronousCoreDataEntity(identifier: identifier) { [weak self] in
            self?.container.contextForWriting() ?? Fail(error: CoreDataPersistentStorageError.storeUnavailable).eraseToAnyPublisher()
        } readPublisher: { [weak self] in
            self?.container.contextForReading() ?? Fail(error: CoreDataPersistentStorageError.storeUnavailable).eraseToAnyPublisher()
        }
        .eraseToAnyEntity()
    }
    
    public func beginTransactions() -> PersistentStoreTransaction {
        PersistentStoreTransaction { [weak self] transaction in
            guard let self = self else {
                return Fail(error: CoreDataPersistentStorageError.storeUnavailable).eraseToAnyPublisher()
            }
            let identifier = self.identifier
            return self.container.contextForWriting()
                .flatMap { context in
                    Future { promise in
                        context.perform {
                            do {
                                try transaction.transactions?(SynchronousCoreDataStorage(identifier: identifier, context: context))
                                promise(.success(CoreDataUpdate(identifier: identifier, context: context)))
                            } catch {
                                promise(.failure(error))
                            }
                        }
                    }
                }
                .eraseToAnyPublisher()
        }
    }
    
}

#endif
