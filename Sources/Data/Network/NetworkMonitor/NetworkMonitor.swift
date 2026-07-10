import Foundation
import Combine

/// Observes device network connectivity.
public protocol NetworkMonitor {
    /// Emits the current connectivity state and every subsequent change.
    func isOnlinePublisher() -> AnyPublisher<Bool, Never>
    /// The current connectivity state.
    func isOnline() -> Bool
}
