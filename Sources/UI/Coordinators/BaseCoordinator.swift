#if canImport(UIKit) && (os(iOS) || os(tvOS) || os(macOS))

import UIKit

@MainActor
public protocol Coordinator: AnyObject {
    
    var childCoordinators: [Coordinator] { get set }
    func start()
    
}

@MainActor
open class BaseCoordinator: Coordinator {
    
    public var childCoordinators: [Coordinator] = []
    
    public init() {}
    
    open func start() {
        // Implementation specific to the coordinator
    }
    
    public func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    public func removeChildCoordinator(_ coordinator: Coordinator?) {
        guard let coordinator = coordinator else { return }
        childCoordinators.removeAll { $0 === coordinator }
    }
    
}

#endif
