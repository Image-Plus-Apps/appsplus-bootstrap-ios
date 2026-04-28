import Foundation

public struct SocketChannel: Equatable, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
