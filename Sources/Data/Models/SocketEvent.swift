import Foundation

public struct SocketEvent: Equatable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension SocketEvent {
    public static let subscribed = SocketEvent(rawValue: "Subscribed")
    public static let connected = SocketEvent(rawValue: "Connected")
    public static let disconnected = SocketEvent(rawValue: "Disconnected")
}
