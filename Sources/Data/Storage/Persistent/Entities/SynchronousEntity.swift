#if canImport(Foundation)

import Foundation

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol SynchronousStorage {
    
    func entity<EntityType>(_ type: EntityType.Type) -> AnySynchronousEntity<EntityType>
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol SynchronousEntity {
    
    associatedtype EntityType
    func fetch() -> SynchronousFetchRequest<EntityType>
    func create() -> SynchronousUpdateRequest<EntityType>
    func update() -> SynchronousUpdateRequest<EntityType>
    func update(orCreate: Bool) -> SynchronousUpdateRequest<EntityType>
    func delete() -> SynchronousDeleteRequest<EntityType>
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension SynchronousEntity {
    
    public func update() -> SynchronousUpdateRequest<EntityType> {
        update(orCreate: false)
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension SynchronousEntity {
    
    public func eraseToAnyEntity() -> AnySynchronousEntity<EntityType> {
        AnySynchronousEntity(entity: self)
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct AnySynchronousEntity<EntityType>: SynchronousEntity, @unchecked Sendable {
    
    private var createMethod: () -> SynchronousUpdateRequest<EntityType>
    private var updateMethod: (Bool) -> SynchronousUpdateRequest<EntityType>
    private var fetchMethod: () -> SynchronousFetchRequest<EntityType>
    private var deleteMethod: () -> SynchronousDeleteRequest<EntityType>
    
    init<E: SynchronousEntity>(entity: E) where E.EntityType == EntityType {
        self.createMethod = {
            entity.create()
        }
        self.updateMethod = {
            entity.update(orCreate: $0)
        }
        self.fetchMethod = {
            entity.fetch()
        }
        self.deleteMethod = {
            entity.delete()
        }
    }
    
    public func create() -> SynchronousUpdateRequest<EntityType> {
        createMethod()
    }
    
    public func update(orCreate: Bool) -> SynchronousUpdateRequest<EntityType> {
        updateMethod(orCreate)
    }
    
    public func fetch() -> SynchronousFetchRequest<EntityType> {
        fetchMethod()
    }
    
    public func delete() -> SynchronousDeleteRequest<EntityType> {
        deleteMethod()
    }
    
}

#endif
