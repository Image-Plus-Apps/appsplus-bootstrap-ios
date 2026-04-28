#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

extension SecureStorageKey {
    static fileprivate let deviceName: SecureStorageKey = "deviceName"
    static fileprivate let authToken: SecureStorageKey = "authToken"
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct AuthSessionProviderImpl: AuthSessionProvider, @unchecked Sendable {
    
    private let secureStorage: SecureStorage
    private let authSessionPassthroughSubject = PassthroughSubject<AnyAuthToken?, Never>()
    
    public var deviceName: String {
        get {
            if let name = secureStorage.string(forKey: .deviceName) {
                return name
            }
            
            let name = UUID().uuidString
            try? secureStorage.setString(name, forKey: .deviceName)
            return name
        }
        set {
            try? secureStorage.setString(newValue, forKey: .deviceName)
        }
    }
    
    public init(secureStorage: SecureStorage) {
        self.secureStorage = secureStorage
    }
    
    public func current<T: AuthTokenProtocol>(as type: T.Type) -> T? {
        secureStorage.value(forKey: .authToken)
    }
    
    public func current() -> AnyAuthToken? {
        secureStorage.value(forKey: .authToken)
    }
    
    public func replace<T: AuthTokenProtocol>(with authToken: T?) -> Bool {
        let replaced = (try? secureStorage.setValue(authToken, forKey: .authToken)) != nil
        authSessionPassthroughSubject.send(authToken?.toAnyAuthToken())
        return replaced
    }
    
    public func authSessionPublisher() -> AnyPublisher<AnyAuthToken?, Never> {
        authSessionPassthroughSubject
            .share()
            .eraseToAnyPublisher()
    }
    
    public func authSessionPublisher<T>(for type: T.Type) -> AnyPublisher<T?, Never> where T : AuthTokenProtocol {
        authSessionPublisher()
            .map { $0?.value as? T }
            .eraseToAnyPublisher()
    }
}

#endif
