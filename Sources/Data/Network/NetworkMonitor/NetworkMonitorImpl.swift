import Foundation
import Combine
import Network

/// `NWPathMonitor`-backed implementation of ``NetworkMonitor``.
public final class NetworkMonitorImpl: NetworkMonitor, @unchecked Sendable {

    @Published private var currentStatus: Bool = true
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    public init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.currentStatus = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    public func isOnlinePublisher() -> AnyPublisher<Bool, Never> {
        $currentStatus
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public func isOnline() -> Bool {
        currentStatus
    }

    deinit {
        monitor.cancel()
    }
}
