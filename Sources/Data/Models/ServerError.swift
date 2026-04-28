#if canImport(Foundation)
import Foundation

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
public struct ServerError: Codable, Error, Sendable {
    
    let message: String
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension ServerError: LocalizedError {
    
    public var errorDescription: String? {
        message
    }
}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.0, *)
extension Data {
    
    public func parseServerError<Field: Hashable & CaseIterable & RawRepresentable>(
        validationFields: Field.Type
    ) -> Error? where Field.RawValue == String {
        do {
            return try ValidationError<Field>(data: self)
        } catch {
            return parseServerError()
        }
    }
    
    public func parseServerError() -> Error? {
        do {
            return try JSONDecoder().decode(ServerError.self, from: self)
        } catch {
            return nil
        }
    }
}

#endif
