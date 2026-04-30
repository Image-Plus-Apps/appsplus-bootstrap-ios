#if canImport(UIKit) && canImport(SwiftUI) && (os(iOS) || os(tvOS) || os(macOS))

import UIKit
import SwiftUI

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
        fatalError("start() must be overridden by subclass")
    }
    
    public func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    public func removeChildCoordinator(_ coordinator: Coordinator?) {
        guard let coordinator = coordinator else { return }
        childCoordinators.removeAll { $0 === coordinator }
    }
    
}

@available(iOS 16.0, tvOS 16.0, macOS 13.0, watchOS 9.0, *)
@MainActor
open class NavigableCoordinator<Route: Hashable>: BaseCoordinator {
    
    public var path = NavigationPath()
    
    public func push(_ route: Route) {
        path.append(route)
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    public func popToRoot() {
        path = NavigationPath()
    }
    
}

#endif
