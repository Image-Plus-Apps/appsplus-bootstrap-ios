import Foundation

public struct SocketMessage: @unchecked Sendable {
    public let channel: SocketChannel?
    public let event: SocketEvent
    public let data: [String: Any?]?
}
