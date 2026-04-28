import Foundation

public struct TimeLock: Sendable {
    
    enum TimeLockError: Error {
        case tooEarly
    }
    
    let timeLockInterval: TimeInterval
    private var lastLock: Date?
    
    public init(timeLockInterval: TimeInterval) {
        self.timeLockInterval = timeLockInterval
    }
    
    public mutating func lock() {
        lastLock = Date()
    }
    
    public func unlock() throws {
        if let lastLock = lastLock {
            guard Date().timeIntervalSince(lastLock) >= timeLockInterval else {
                throw TimeLockError.tooEarly
            }
        }
    }
    
}

