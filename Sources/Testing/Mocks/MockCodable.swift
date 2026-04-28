#if canImport(Foundation)

import Foundation

public struct MockCodable: Codable, Equatable, Sendable {
    let value: String
}

#endif
