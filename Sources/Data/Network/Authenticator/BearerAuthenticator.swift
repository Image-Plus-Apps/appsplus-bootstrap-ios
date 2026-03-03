#if canImport(Foundation)

import Foundation

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
public class BearerAuthenticator<AuthToken: AuthTokenProtocol>: Authenticator {

    private let authSessionProvider: AuthSessionProvider
    private let refreshUrl: URL?
    private let version: String
    private var isRefreshing = false
    
    /// A callback that provides additional headers to be set on all authenticated requests.
    /// The callback receives the current auth token and returns a dictionary of header fields and values.
    public var globalHeadersProvider: ((AuthToken) -> [HTTPHeaderField: HTTPHeaderValue])?

    public init(authSessionProvider: AuthSessionProvider, refreshUrl: URL?, bundleIdentifier: String, version: String) {
        self.authSessionProvider = authSessionProvider
        self.refreshUrl = refreshUrl
        self.version = version
    }
    
    /// Convenience initializer with global headers provider
    public init(
        authSessionProvider: AuthSessionProvider,
        refreshUrl: URL?,
        bundleIdentifier: String,
        version: String,
        globalHeadersProvider: ((AuthToken) -> [HTTPHeaderField: HTTPHeaderValue])?
    ) {
        self.authSessionProvider = authSessionProvider
        self.refreshUrl = refreshUrl
        self.version = version
        self.globalHeadersProvider = globalHeadersProvider
    }

    private func refreshToken(authSession: AuthToken, urlSession: URLSession) async throws -> AuthToken {
        guard let refreshUrl = refreshUrl else {
            throw AuthenticatorError.refreshFailed
        }

        // Ensure only one refresh operation at a time
        if isRefreshing {
            throw AuthenticatorError.refreshFailed // Handle concurrent refresh requests
        }

        isRefreshing = true
        defer { isRefreshing = false }

        var request = URLRequest(url: refreshUrl, versionNumber: version)
        request.set(httpMethod: .post)
        try request.set(httpBody: ["device_name": authSessionProvider.deviceName])
        request.set(headerField: .authorization, value: .bearer(token: authSession.refreshToken))

        do {
            let (data, _) = try await urlSession.data(for: request)
            let token = try JSONDecoder().decode(AuthToken.self, from: data)

            guard authSessionProvider.replace(with: token) else {
                _ = authSessionProvider.remove()
                throw AuthenticatorError.refreshFailed
            }
            return token
        } catch {
            _ = authSessionProvider.remove()
            throw AuthenticatorError.refreshFailed
        }
    }

    public func authenticate(request: Request, forceRefresh: Bool, urlSession: URLSession) async throws -> URLRequest {
        guard request.requiresAuthentication else {
            return request.urlRequest
        }

        guard let authSession = authSessionProvider.current(as: AuthToken.self) else {
            throw AuthenticatorError.noAuthSession
        }

        let token: AuthToken
        if forceRefresh {
            token = try await refreshToken(authSession: authSession, urlSession: urlSession)
        } else {
            token = authSession
        }
        
        var urlRequest = request.urlRequest
        urlRequest.set(headerField: .authorization, value: .bearer(token: token.accessToken))
        
        // Apply global headers if provider is set
        if let globalHeaders = globalHeadersProvider?(token) {
            for (field, value) in globalHeaders {
                urlRequest.set(headerField: field, value: value)
            }
        }
        
        return urlRequest
    }
}

#endif
