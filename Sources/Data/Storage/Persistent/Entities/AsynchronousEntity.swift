#if canImport(Foundation) && canImport(Combine)

import Foundation

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol AsynchronousEntity {
    
    associatedtype EntityType
    
    func create() -> AsynchronousUpdateRequest<EntityType>
    func update() -> AsynchronousUpdateRequest<EntityType>
    func update(orCreate: Bool) -> AsynchronousUpdateRequest<EntityType>
    func fetch() -> AsynchronousFetchRequest<EntityType>
    func delete() -> AsynchronousDeleteRequest<EntityType>
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousEntity {
    
    public func update() -> AsynchronousUpdateRequest<EntityType> {
        return update(orCreate: false)
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AsynchronousEntity {
    
    public func eraseToAnyEntity() -> AnyAsynchronousEntity<EntityType> {
        AnyAsynchronousEntity(entity: self)
    }
    
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct AnyAsynchronousEntity<EntityType>: AsynchronousEntity, @unchecked Sendable {
    
    private var createMethod: () -> AsynchronousUpdateRequest<EntityType>
    private var updateMethod: (Bool) -> AsynchronousUpdateRequest<EntityType>
    private var fetchMethod: () -> AsynchronousFetchRequest<EntityType>
    private var deleteMethod: () -> AsynchronousDeleteRequest<EntityType>
    
    init<E: AsynchronousEntity>(entity: E) where E.EntityType == EntityType {
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
    
    public func create() -> AsynchronousUpdateRequest<EntityType> {
        createMethod()
    }
    
    public func update(orCreate: Bool) -> AsynchronousUpdateRequest<EntityType> {
        updateMethod(orCreate)
    }
    
    public func fetch() -> AsynchronousFetchRequest<EntityType> {
        fetchMethod()
    }
    
    public func delete() -> AsynchronousDeleteRequest<EntityType> {
        deleteMethod()
    }
    
}

#endif
