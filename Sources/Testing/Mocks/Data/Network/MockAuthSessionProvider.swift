import AppsPlusData
import Foundation
import Combine

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public class MockAuthSessionProvider<AuthToken: AuthTokenProtocol>: AuthSessionProvider, @unchecked Sendable {
    
    public var currentAuthSession: AuthToken?
    public var replacedAuthSession: AuthToken?
    public var didCallReplace = false
    public var replaceSuccess = false
    public var currentDeviceName: String?
    public var authSessionPublisherPassthroughSubject = PassthroughSubject<AuthToken?, Never>()
    
    public init() {
        
    }
    
    public func current() -> AnyAuthToken? {
        currentAuthSession?.toAnyAuthToken()
    }
    
    public func current<T>(as type: T.Type) -> T? where T : AuthTokenProtocol {
        return currentAuthSession as? T
    }
    
    public func replace<T>(with authToken: T?) -> Bool where T : AuthTokenProtocol {
        didCallReplace = true
        replacedAuthSession = authToken as? AuthToken
        return replaceSuccess
    }
    
    public var deviceName: String {
        return currentDeviceName!
    }
    
    public func authSessionPublisher<T>(for type: T.Type) -> AnyPublisher<T?, Never> where T : AuthTokenProtocol {
        authSessionPublisherPassthroughSubject
            .share()
            .map { $0 as? T }
            .eraseToAnyPublisher()
    }
    
    public func authSessionPublisher() -> AnyPublisher<AnyAuthToken?, Never> {
        authSessionPublisherPassthroughSubject
            .share()
            .map { $0?.toAnyAuthToken() }
            .eraseToAnyPublisher()
    }
    
}
