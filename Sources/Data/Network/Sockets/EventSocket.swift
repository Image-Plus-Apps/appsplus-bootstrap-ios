#if canImport(Foundation) && canImport(Combine)

import Foundation
import Combine

public protocol EventSocket: Sendable {
    func disconnect()
    func subscribe(to channel: SocketChannel, for events: [SocketEvent]) -> AnyPublisher<SocketMessage, Never>
}

#endif
