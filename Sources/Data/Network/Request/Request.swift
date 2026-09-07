#if canImport(Foundation)

import Foundation

public protocol Request: Sendable {
    
    var urlRequest: URLRequest { get }
    var requiresAuthentication: Bool { get }
    
    /// Whether a `401` on this request should be retried once with a forced credential refresh.
    ///
    /// `true` by default, which is the behaviour every request has always had. Set it to `false` where the
    /// caller needs to read the `401` itself: `NetworkerImpl` otherwise turns an unauthorised response into
    /// a retry and then a thrown `NetworkError.notAuthenticated`, so the status code never reaches the
    /// caller and a rejected credential cannot be told apart from a transport failure.
    ///
    /// A credential check at sign-in is the case this exists for — the `401` *is* the answer.
    ///
    /// The retry is also skipped when the networker has it turned off for every request. See
    /// `NetworkerImpl.init(session:authenticator:retriesOnUnauthorized:)`.
    var retriesOnUnauthorized: Bool { get }
    
}

public extension Request {
    
    var retriesOnUnauthorized: Bool { true }
    
}

public struct AuthenticatedRequest: Request, Sendable {
    
    public let urlRequest: URLRequest
    public let requiresAuthentication = true
    public let retriesOnUnauthorized: Bool
    
    public init(urlRequest: URLRequest, retriesOnUnauthorized: Bool = true) {
        self.urlRequest = urlRequest
        self.retriesOnUnauthorized = retriesOnUnauthorized
    }
    
}

public struct PublicRequest: Request, Sendable {
    
    public let urlRequest: URLRequest
    public let requiresAuthentication = false
    public let retriesOnUnauthorized: Bool
    
    /// - Parameter retriesOnUnauthorized: `true` by default, matching every other request — although a
    /// request that carries no credentials has nothing to refresh, so there is rarely anything for the
    /// retry to change. The default is kept for compatibility rather than because it is useful here.
    public init(urlRequest: URLRequest, retriesOnUnauthorized: Bool = true) {
        self.urlRequest = urlRequest
        self.retriesOnUnauthorized = retriesOnUnauthorized
    }
    
}

#endif
