import AppsPlusData
import Combine

public class MockEventSocket: EventSocket, @unchecked Sendable {
    
    public init() {}
    
    public var disconnectCalled = false
    public func disconnect() {
        disconnectCalled = true
    }
    
    public var subscribeToChannel: SocketChannel?
    public var subscribeEvents: [SocketEvent]?
    public var subscriptionPublisher: AnyPublisher<SocketMessage, Never> = PassthroughSubject<SocketMessage, Never>().eraseToAnyPublisher()
    public func subscribe(to channel: SocketChannel, for events: [SocketEvent]) -> AnyPublisher<SocketMessage, Never> {
        subscribeToChannel = channel
        subscribeEvents = events
        return subscriptionPublisher
    }
    
}
