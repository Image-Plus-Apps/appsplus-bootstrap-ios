#if canImport(Foundation)

import Foundation

public enum ValidationParseError: Error, Sendable {
    case failedToParse
}

public struct ValidationError<Field: Hashable & CaseIterable & RawRepresentable & Sendable>: Equatable, Error, Sendable where Field.RawValue == String {
    public let errors: [Field: [String]]
    
    public init(errors: [Field: [String]]) {
        self.errors = errors
    }
}

public extension ValidationError {
    
    init(data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errors = json["errors"] as? [String: [String]]  else {
            throw ValidationParseError.failedToParse
        }
        let validationErrors: [Field: [String]] = Field.allCases.reduce(into: [Field: [String]]()) { dictionary, field in
            let arrayValues = errors.keys.filter { $0.hasPrefix("\(field.rawValue).") }
                .flatMap { errors[$0] ?? [] }
            
            dictionary[field] = errors[field.rawValue, default: []] + arrayValues
        }.filter { !$0.value.isEmpty }
        guard !validationErrors.isEmpty else {
            throw ValidationParseError.failedToParse
        }
        self.errors = validationErrors
    }
    
}

extension ValidationError: LocalizedError {
    
    public var errorDescription: String? {
        errors
            .values
            .flatMap { $0 }
            .joined(separator: "\n")
    }
    
}

#endif
