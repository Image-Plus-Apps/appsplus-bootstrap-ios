//#if canImport(Foundation) && canImport(Combine)
//
//import Foundation
//import Combine
//
//@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
//public struct NetworkerImpl: Network, @unchecked Sendable {
//    
//    private enum RequestError: Error {
//        case unauthorized
//        case authenticator(AuthenticatorError)
//        case urlError(URLError)
//        case unknown
//    }
//    
//    private let session: URLSession
//    private let authenticator: Authenticator
//    
//    public init(session: URLSession, authenticator: Authenticator) {
//        self.session = session
//        self.authenticator = authenticator
//    }
//    
//    public func publisher(for request: Request) -> AnyPublisher<(data: Data, response: URLResponse), NetworkError> {
//        publisher(for: request, forceAuthRefresh: false)
//            .mapError {
//                switch $0 {
//                case .unknown:
//                    return .urlError(URLError(.unknown))
//                case .authenticator, .unauthorized:
//                    return .notAuthenticated
//                case .urlError(let error):
//                    return .urlError(error)
//                }
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    private func publisher(for request: Request, forceAuthRefresh: Bool) -> AnyPublisher<(data: Data, response: URLResponse), RequestError> {
//        authenticator
//            .authenticate(request: request, forceRefresh: forceAuthRefresh, urlSession: session)
//            .mapError { RequestError.authenticator($0) }
//            .flatMap {
//                session.dataTaskPublisher(for: $0)
//                    .retry(3)
//                    .mapError { RequestError.urlError($0) }
//            }
//            .tryMap { (data, response) throws -> (Data, URLResponse) in
//                if let httpResponse = response as? HTTPURLResponse,
//                   httpResponse.isUnauthorized {
//                    throw RequestError.unauthorized
//                }
//                return (data, response)
//            }
//            .mapError { $0 as? RequestError ?? .unknown }
//            .tryCatch { error -> AnyPublisher<(data: Data, response: URLResponse), RequestError> in
//                if case .unauthorized = error, !forceAuthRefresh {
//                    return publisher(for: request, forceAuthRefresh: true)
//                } else {
//                    throw error
//                }
//            }
//            .mapError { $0 as? RequestError ?? .unknown }
//            .eraseToAnyPublisher()
//    }
//    
//}
//
//#endif

#if canImport(Foundation)

import Foundation

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
public struct NetworkerImpl: Network {
    
    private enum RequestError: Error {
        case unauthorized
        case authenticator(AuthenticatorError)
        case urlError(URLError)
        case unknown

        /// What the caller is given. `RequestError` is this type's own bookkeeping and never leaves it —
        /// `perform(request:)` maps every case through here.
        var networkError: NetworkError {
            switch self {
            case .unauthorized, .authenticator:
                return .notAuthenticated
            case .urlError(let urlError):
                return .urlError(urlError)
            case .unknown:
                return .urlError(URLError(.unknown))
            }
        }
    }
    
    private let session: URLSession
    private let authenticator: Authenticator
    private let retriesOnUnauthorized: Bool
    
    /// - Parameter retriesOnUnauthorized: whether a `401` is retried once with a forced credential
    /// refresh. `true` by default, which is the behaviour this type has always had. Pass `false` to turn
    /// the retry off for **every** request — an API that authenticates each call outright, HTTP Basic for
    /// instance, has nothing to refresh, so the retry can only ever cost a second round trip and hide the
    /// `401` from the caller.
    ///
    /// A single request can opt out on its own through `Request.retriesOnUnauthorized`. **The retry
    /// happens only where both agree to it**, so either side can switch it off and neither can force it
    /// back on.
    public init(session: URLSession, authenticator: Authenticator, retriesOnUnauthorized: Bool = true) {
        self.session = session
        self.authenticator = authenticator
        self.retriesOnUnauthorized = retriesOnUnauthorized
    }
    
    public func perform(request: Request) async throws -> (data: Data, response: HTTPURLResponse) {
        let values: (data: Data, response: URLResponse)
        do {
            values = try await perform(request: request, forceAuthRefresh: false)
        } catch let error as RequestError {
            throw error.networkError
        }
        
        guard let response = values.response as? HTTPURLResponse else {
            throw NetworkError.urlError(URLError(.badServerResponse))
        }
        
        return (data: values.data, response: response)
    }
    
    private func perform(request: Request, forceAuthRefresh: Bool) async throws -> (data: Data, response: URLResponse) {
        do {
            let authenticatedRequest = try await authenticator.authenticate(request: request, forceRefresh: forceAuthRefresh, urlSession: session)
            let (data, response) = try await session.data(for: authenticatedRequest)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnauthorized {
                if !forceAuthRefresh, retriesOnUnauthorized, request.retriesOnUnauthorized {
                    return try await perform(request: request, forceAuthRefresh: true)
                } else if forceAuthRefresh {
                    throw RequestError.unauthorized
                }
                // The retry is turned off, here or on the request itself, so the `401` is handed back as
                // the response it is rather than thrown. This is the only way a caller can read the status
                // code of an unauthorised response — see `Request.retriesOnUnauthorized`.
            }
            
            return (data, response)
        } catch let error as RequestError {
            // Already classified, so it passes straight through. Without this the `catch` below rewrites
            // it to `.unknown`, and two things it must not touch are thrown from inside the `do` above:
            // the `.unauthorized` raised when a forced refresh still comes back `401`, and whatever the
            // retry itself threw. Both were arriving at the caller as `.urlError(.unknown)` — so a
            // rejected credential was reported as a transport failure and `.notAuthenticated` could not
            // actually be produced by this type.
            throw error
        } catch let error as AuthenticatorError {
            throw RequestError.authenticator(error)
        } catch let error as URLError {
            throw RequestError.urlError(error)
        } catch {
            throw RequestError.unknown
        }
    }
}

#endif
