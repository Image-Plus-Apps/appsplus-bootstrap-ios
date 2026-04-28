#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public protocol AuthSessionProvider: Sendable {
    var deviceName: String { get }
    func current() -> AnyAuthToken?
    func current<T: AuthTokenProtocol>(as type: T.Type) -> T?
    func replace<T: AuthTokenProtocol>(with authToken: T?) -> Bool
    func authSessionPublisher() -> AnyPublisher<AnyAuthToken?, Never>
    func authSessionPublisher<T: AuthTokenProtocol>(for type: T.Type) -> AnyPublisher<T?, Never>
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension AuthSessionProvider {
    
    public func remove() -> Bool {
        replace(with: Optional<AnyAuthToken>.none)
    }
    
}

#endif
