#if canImport(Foundation)

import Foundation

public struct HTTPMethod: Sendable {
    fileprivate let rawValue: String
}

extension HTTPMethod: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}

extension HTTPMethod {
    public static let get: Self = "GET"
    public static let patch: Self = "PATCH"
    public static let post: Self = "POST"
    public static let put: Self = "PUT"
    public static let delete: Self = "DELETE"
}

extension URLRequest {
    
    public mutating func set(httpMethod: HTTPMethod) {
        self.httpMethod = httpMethod.rawValue
    }
    
}

#endif
