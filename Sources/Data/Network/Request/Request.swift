#if canImport(Foundation)

import Foundation

public protocol Request: Sendable {
    
    var urlRequest: URLRequest { get }
    var requiresAuthentication: Bool { get }
    
}

public struct AuthenticatedRequest: Request, Sendable {
    
    public let urlRequest: URLRequest
    public let requiresAuthentication = true
    
    public init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
}

public struct PublicRequest: Request, Sendable {
    
    public let urlRequest: URLRequest
    public let requiresAuthentication = false
    
    public init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
    
}

#endif
