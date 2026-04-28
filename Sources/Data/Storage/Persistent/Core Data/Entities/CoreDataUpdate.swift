#if canImport(Foundation) && canImport(CoreData) && canImport(Combine)

import Foundation
import CoreData
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct CoreDataUpdate: PersistentStoreUpdate, @unchecked Sendable {
    
    let identifier: String
    let context: NSManagedObjectContext
    
    func commit() -> AnyPublisher<Void, Error> {
        Future { promise in
            context.perform {
                do {
                    if context.hasChanges {
                        try context.save()
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
}

#endif
