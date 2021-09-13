#if canImport(Foundation) && canImport(CoreData) && canImport(Combine)

import Foundation
import CoreData

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
struct CoreDataEntity {
    
    let identifier: String
    let context: NSManagedObjectContext
    
    func delete(request: NSFetchRequest<NSFetchRequestResult>) -> PersistentStoreUpdate {
        (try? context.fetch(request))?.compactMap { $0 as? NSManagedObject }
            .forEach { context.delete($0) }
        return CoreDataUpdate(identifier: identifier, context: context)
    }
    
    func update<EntityType>(
        entityName: String,
        shouldCreate: Bool,
        shouldUpdate: Bool,
        fetchRequest: NSFetchRequest<NSFetchRequestResult>,
        prevalidation: ((EntityType, SynchronousStorage) -> Bool)?,
        modifier: ((EntityType, SynchronousStorage) -> Void)?
    ) -> PersistentStoreUpdate {
        if shouldUpdate {
            let fetchResults = (try? context.fetch(fetchRequest))?.compactMap { $0 as? EntityType } ?? []
            if fetchResults.isEmpty && !shouldCreate {
                return CoreDataUpdate(identifier: identifier, context: context)
            } else if fetchResults.isEmpty && shouldCreate {
                return create(
                    entityName: entityName,
                    prevalidation: prevalidation,
                    modifier: modifier
                )
            } else {
                fetchResults.forEach {
                    modifier?($0, SynchronousCoreDataStorage(identifier: identifier, context: context))
                }
                return CoreDataUpdate(identifier: identifier, context: context)
            }
        } else if shouldCreate {
            return create(
                entityName: entityName,
                prevalidation: prevalidation,
                modifier: modifier
            )
        } else {
            return CoreDataUpdate(identifier: identifier, context: context)
        }
    }
    
    func fetch<EntityType>(request: NSFetchRequest<NSFetchRequestResult>) -> [EntityType] {
        (try? context.fetch(request))?.compactMap { $0 as? EntityType } ?? []
    }
    
    private func create<EntityType>(
        entityName: String,
        prevalidation: ((EntityType, SynchronousStorage) -> Bool)?,
        modifier: ((EntityType, SynchronousStorage) -> Void)?
    ) -> PersistentStoreUpdate {
        let storage = SynchronousCoreDataStorage(identifier: identifier, context: context)
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as? EntityType,
              prevalidation?(entity, storage) != false else {
            return CoreDataUpdate(identifier: identifier, context: context)
        }
        modifier?(entity, storage)
        return CoreDataUpdate(identifier: identifier, context: context)
    }
    
}

#endif
