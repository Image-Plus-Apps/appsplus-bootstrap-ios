import Foundation

public enum RetryState: Hashable, Sendable {
    case refresh
    case page
}

public enum PagingState: Hashable, @unchecked Sendable {
    case idle
    case initialLoad
    case initialLoadError(ErrorWrapper)
    case refreshing
    case refreshingError(ErrorWrapper)
    case paging
    case pagingError(ErrorWrapper)
    
    public func canPage() -> Bool {
        self == .idle
    }
    
    public func canRefresh() -> Bool {
        switch self {
        case .idle, .refreshing, .refreshingError, .paging, .pagingError:
            return true
        default:
            return false
        }
    }
    
    mutating public func failed(_ error: Error) {
        let error = error.wrapped
        switch self {
        case .initialLoad:
            self = .initialLoadError(error)
        case .refreshing:
            self = .refreshingError(error)
        case .paging:
            self = .pagingError(error)
        default:
            break
        }
    }
    
    public func retry() -> RetryState? {
        switch self {
        case .idle, .refreshingError, .initialLoadError:
            return .refresh
        case .pagingError:
            return .page
        default:
            return nil
        }
    }
}

public struct ErrorWrapper: Error, Hashable, @unchecked Sendable {
    public let error: Error
    
    public static func == (lhs: ErrorWrapper, rhs: ErrorWrapper) -> Bool {
        return lhs.error.localizedDescription == rhs.error.localizedDescription
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(error.localizedDescription)
    }
}

public extension Error {
    var wrapped: ErrorWrapper {
        return ErrorWrapper(error: self)
    }
}
