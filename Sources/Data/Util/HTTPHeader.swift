#if canImport(Foundation)

import Foundation

public struct HTTPHeaderField: Hashable, Sendable {
    fileprivate let rawValue: String
    
    public init(_ value: String) {
        self.rawValue = value
    }
}

extension HTTPHeaderField: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}

extension HTTPHeaderField {
    public static let authorization: Self = "Authorization"
    public static let contentType: Self = "Content-Type"
    public static let accept: Self = "Accept"
    public static let deviceType: Self = "Device-Type"
    public static let deviceVersion: Self = "Device-Version"
}

public struct HTTPHeaderValue: Sendable {
    fileprivate let rawValue: String
}

extension HTTPHeaderValue {
    
    public init(_ value: String) {
        self.rawValue = value
    }
    
}

extension HTTPHeaderValue: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}

extension HTTPHeaderValue {
    public static var applicationJson: HTTPHeaderValue = "application/json"
    public static var iOS: HTTPHeaderValue = "ios"
    public static var macOS: HTTPHeaderValue = "macos"
    public static var watchOS: HTTPHeaderValue = "watchos"
    public static var tvOS: HTTPHeaderValue = "tvos"
    
    public static func bearer(token: String) -> HTTPHeaderValue {
        "Bearer \(token)"
    }
}

extension URLRequest {
    
    public mutating func set(headerField: HTTPHeaderField, value: HTTPHeaderValue?) {
        setValue(value?.rawValue, forHTTPHeaderField: headerField.rawValue)
    }
}

#endif
