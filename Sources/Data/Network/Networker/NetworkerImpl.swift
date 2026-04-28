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
    }
    
    private let session: URLSession
    private let authenticator: Authenticator
    
    public init(session: URLSession, authenticator: Authenticator) {
        self.session = session
        self.authenticator = authenticator
    }
    
    public func perform(request: Request) async throws -> (data: Data, response: HTTPURLResponse) {
        let values = try await perform(request: request, forceAuthRefresh: false)
        
        guard let response = values.response as? HTTPURLResponse else {
            throw NetworkError.urlError(URLError(.badServerResponse))
        }
        
        return (data: values.data, response: response)
    }
    
    private func perform(request: Request) async throws -> (data: Data, response: URLResponse) {
        do {
            return try await perform(request: request, forceAuthRefresh: false)
        } catch let error as RequestError {
            switch error {
            case .unknown:
                throw NetworkError.urlError(URLError(.unknown))
            case .authenticator, .unauthorized:
                throw NetworkError.notAuthenticated
            case .urlError(let urlError):
                throw NetworkError.urlError(urlError)
            }
        }
    }
    
    private func perform(request: Request, forceAuthRefresh: Bool) async throws -> (data: Data, response: URLResponse) {
        do {
            let authenticatedRequest = try await authenticator.authenticate(request: request, forceRefresh: forceAuthRefresh, urlSession: session)
            let (data, response) = try await session.data(for: authenticatedRequest)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnauthorized {
                if !forceAuthRefresh {
                    return try await perform(request: request, forceAuthRefresh: true)
                } else {
                    throw RequestError.unauthorized
                }
            }
            
            return (data, response)
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
