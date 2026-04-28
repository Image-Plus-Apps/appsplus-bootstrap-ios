#if canImport(Foundation)

import Foundation

public protocol AuthTokenProtocol: Codable, Equatable, Sendable {
    var accessToken: String { get }
    var refreshToken: String { get }
}

extension AuthTokenProtocol {
    
    public func toAnyAuthToken() -> AnyAuthToken {
        AnyAuthToken(token: self)
    }
    
}

public struct AnyAuthToken: AuthTokenProtocol, Equatable, Codable, @unchecked Sendable {
    
    private struct SimpleToken: AuthTokenProtocol {
        let accessToken: String
        let refreshToken: String
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "token"
        case refreshToken = "refresh_token"
    }
    
    public static func == (lhs: AnyAuthToken, rhs: AnyAuthToken) -> Bool {
        lhs.equals(rhs.value)
    }
    
    let value: Any
    public let accessToken: String
    public let refreshToken: String
    private let equals: (Any) -> Bool
    private let encoding: (Encoder) throws -> Void
    
    init<T: AuthTokenProtocol>(token: T) {
        self.value = token
        self.accessToken = token.accessToken
        self.refreshToken = token.refreshToken
        equals = { value in
            guard let value = value as? T else {
                return false
            }
            return token == value
        }
        encoding = { try token.encode(to: $0) }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let accessToken = try container.decode(String.self, forKey: .accessToken)
        let refreshToken = try container.decode(String.self, forKey: .refreshToken)
        self.init(token: SimpleToken(accessToken: accessToken, refreshToken: refreshToken))
    }
    
    public func encode(to encoder: Encoder) throws {
        try encoding(encoder)
    }
    
    func cast<T: AuthTokenProtocol>() -> T? {
        value as? T
    }
    
}

#endif
