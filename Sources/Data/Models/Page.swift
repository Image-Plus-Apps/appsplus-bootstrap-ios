#if canImport(Foundation)

import Foundation

public struct Page<T> {
    
    public struct Meta: Equatable, Codable {
        public let currentPage: Int
        public let lastPage: Int
        public let total: Int?
        
        public init(currentPage: Int, lastPage: Int, total: Int?) {
            self.currentPage = currentPage
            self.lastPage = lastPage
            self.total = total
        }
    }
    
    public let data: [T]
    public let meta: Meta
    
    public init(data: [T], meta: Meta) {
        self.data = data
        self.meta = meta
    }
}

extension Page: Codable where T: Codable {}
extension Page: Equatable where T: Equatable {}
extension Page: Sendable where T: Sendable {}
extension Page.Meta: Sendable {}

extension Page {
    
    public func map<S>(_ transform: (T) throws -> S) rethrows -> Page<S> {
        let transformedData = try data.map(transform)
        return Page<S>(data: transformedData, meta: .init(currentPage: meta.currentPage, lastPage: meta.lastPage, total: meta.total))
    }
    
    public func compactMap<S>(_ transform: (T) throws -> S?) rethrows -> Page<S> {
        let transformedData = try data.compactMap(transform)
        return Page<S>(data: transformedData, meta: .init(currentPage: meta.currentPage, lastPage: meta.lastPage, total: meta.total))
    }
    
    public func flatMap<N, S>(_ transform: ([N]) throws -> [S]) rethrows -> Page<S> where T == [N] {
        let transformedData = try data.flatMap(transform)
        return Page<S>(data: transformedData, meta: .init(currentPage: meta.currentPage, lastPage: meta.lastPage, total: meta.total))
    }
}

extension Page {
    
    public var isLastPage: Bool {
        meta.currentPage >= meta.lastPage
    }
    
    public var hasNextPage: Bool {
        meta.currentPage < meta.lastPage
    }
    
}

#endif
