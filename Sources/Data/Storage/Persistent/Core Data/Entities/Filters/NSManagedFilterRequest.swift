#if canImport(Foundation) && canImport(CoreData)

import Foundation
import CoreData

extension FilterRequest where Entity: NSManagedObject {
    
    public typealias KeyPathFilterBuilder<Value> = () -> KeyPathFilter<Entity, Value>
    
    public func suchThat<Value>(filter: KeyPathFilterBuilder<Value>) -> Self {
        suchThat(predicate: filter().predicate)
    }
    
    public func and<Value>(filter: KeyPathFilterBuilder<Value>) -> Self {
        and(predicate: filter().predicate)
    }
    
    public func or<Value>(filter: KeyPathFilterBuilder<Value>) -> Self {
        or(predicate: filter().predicate)
    }
    
    public func excluding<Value>(filter: KeyPathFilterBuilder<Value>) -> Self {
        excluding(predicate: filter().predicate)
    }
    
}

private func contained<Root: NSManagedObject, Value: CVarArgConvertible>(in array: [Value], for keyPath: KeyPath<Root, Value>) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) IN %@", array.map { $0.asCVarArg() })
}

private func contained<Root: NSManagedObject, Value: CVarArgConvertible>(in array: [Value?], for keyPath: KeyPath<Root, Value?>) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) IN %@", array.map { $0?.asCVarArg() })
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func suchThat<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value>, containedIn array: [Value]) -> Self {
        suchThat(predicate: contained(in: array, for: keyPath))
    }
    
    public func and<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value>, containedIn array: [Value]) -> Self {
        and(predicate: contained(in: array, for: keyPath))
    }
    
    public func or<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value>, containedIn array: [Value]) -> Self {
        or(predicate: contained(in: array, for: keyPath))
    }
    
    public func excluding<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value>, containedIn array: [Value]) -> Self {
        excluding(predicate: contained(in: array, for: keyPath))
    }
    
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func suchThat<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value?>, containedIn array: [Value?]) -> Self {
        suchThat(predicate: contained(in: array, for: keyPath))
    }
    
    public func and<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value?>, containedIn array: [Value?]) -> Self {
        and(predicate: contained(in: array, for: keyPath))
    }
    
    public func or<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value?>, containedIn array: [Value?]) -> Self {
        or(predicate: contained(in: array, for: keyPath))
    }
    
    public func excluding<Value: CVarArgConvertible>(_ keyPath: KeyPath<Entity, Value?>, containedIn array: [Value?]) -> Self {
        excluding(predicate: contained(in: array, for: keyPath))
    }
    
}

public struct StringFilterOptions: OptionSet, CustomStringConvertible {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let caseInsensitive = StringFilterOptions(rawValue: 1 << 0)
    public static let diacriticInsensitive = StringFilterOptions(rawValue: 1 << 1)
    
    public var description: String {
        if isEmpty {
            return ""
        } else {
            var items = [String]()
            if contains(.caseInsensitive) {
                items.append("c")
            }
            if contains(.diacriticInsensitive) {
                items.append("d")
            }
            return "[\(items.joined())]"
        }
    }
}

private func predicate<Entity: NSManagedObject>(keyPath: KeyPath<Entity, String?>, like value: String, options: StringFilterOptions) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) LIKE\(options) %@", value)
}

private func predicate<Entity: NSManagedObject>(keyPath: KeyPath<Entity, String?>, contains value: String, options: StringFilterOptions) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) CONTAINS\(options) %@", value)
}

private func predicate<Entity: NSManagedObject>(keyPath: KeyPath<Entity, String?>, beginsWith value: String, options: StringFilterOptions) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) BEGINSWITH\(options) %@", value)
}

private func predicate<Entity: NSManagedObject>(keyPath: KeyPath<Entity, String?>, endsWith value: String, options: StringFilterOptions) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) ENDSWITH\(options) %@", value)
}

private func predicate<Entity: NSManagedObject>(keyPath: KeyPath<Entity, String?>, matches value: String, options: StringFilterOptions) -> NSPredicate {
    NSPredicate(format: "\(keyPath.keyPath) MATCHES\(options) %@", value)
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func suchThat(_ keyPath: KeyPath<Entity, String?>, like value: String, options: StringFilterOptions = []) -> Self {
        suchThat(predicate: predicate(keyPath: keyPath, like: value, options: options))
    }
    
    public func suchThat(_ keyPath: KeyPath<Entity, String?>, contains value: String, options: StringFilterOptions = []) -> Self {
        suchThat(predicate: predicate(keyPath: keyPath, contains: value, options: options))
    }
    
    public func suchThat(_ keyPath: KeyPath<Entity, String?>, beginsWith value: String, options: StringFilterOptions = []) -> Self {
        suchThat(predicate: predicate(keyPath: keyPath, beginsWith: value, options: options))
    }
    
    public func suchThat(_ keyPath: KeyPath<Entity, String?>, endsWith value: String, options: StringFilterOptions = []) -> Self {
        suchThat(predicate: predicate(keyPath: keyPath, endsWith: value, options: options))
    }
    
    public func suchThat(_ keyPath: KeyPath<Entity, String?>, matches value: String, options: StringFilterOptions = []) -> Self {
        suchThat(predicate: predicate(keyPath: keyPath, matches: value, options: options))
    }
    
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func and(_ keyPath: KeyPath<Entity, String?>, like value: String, options: StringFilterOptions = []) -> Self {
        and(predicate: predicate(keyPath: keyPath, like: value, options: options))
    }
    
    public func and(_ keyPath: KeyPath<Entity, String?>, contains value: String, options: StringFilterOptions = []) -> Self {
        and(predicate: predicate(keyPath: keyPath, contains: value, options: options))
    }
    
    public func and(_ keyPath: KeyPath<Entity, String?>, beginsWith value: String, options: StringFilterOptions = []) -> Self {
        and(predicate: predicate(keyPath: keyPath, beginsWith: value, options: options))
    }
    
    public func and(_ keyPath: KeyPath<Entity, String?>, endsWith value: String, options: StringFilterOptions = []) -> Self {
        and(predicate: predicate(keyPath: keyPath, endsWith: value, options: options))
    }
    
    public func and(_ keyPath: KeyPath<Entity, String?>, matches value: String, options: StringFilterOptions = []) -> Self {
        and(predicate: predicate(keyPath: keyPath, matches: value, options: options))
    }
    
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func or(_ keyPath: KeyPath<Entity, String?>, like value: String, options: StringFilterOptions = []) -> Self {
        or(predicate: predicate(keyPath: keyPath, like: value, options: options))
    }
    
    public func or(_ keyPath: KeyPath<Entity, String?>, contains value: String, options: StringFilterOptions = []) -> Self {
        or(predicate: predicate(keyPath: keyPath, contains: value, options: options))
    }
    
    public func or(_ keyPath: KeyPath<Entity, String?>, beginsWith value: String, options: StringFilterOptions = []) -> Self {
        or(predicate: predicate(keyPath: keyPath, beginsWith: value, options: options))
    }
    
    public func or(_ keyPath: KeyPath<Entity, String?>, endsWith value: String, options: StringFilterOptions = []) -> Self {
        or(predicate: predicate(keyPath: keyPath, endsWith: value, options: options))
    }
    
    public func or(_ keyPath: KeyPath<Entity, String?>, matches value: String, options: StringFilterOptions = []) -> Self {
        or(predicate: predicate(keyPath: keyPath, matches: value, options: options))
    }
    
}

extension FilterRequest where Entity: NSManagedObject {
    
    public func excluding(_ keyPath: KeyPath<Entity, String?>, like value: String, options: StringFilterOptions = []) -> Self {
        excluding(predicate: predicate(keyPath: keyPath, like: value, options: options))
    }
    
    public func excluding(_ keyPath: KeyPath<Entity, String?>, contains value: String, options: StringFilterOptions = []) -> Self {
        excluding(predicate: predicate(keyPath: keyPath, contains: value, options: options))
    }
    
    public func excluding(_ keyPath: KeyPath<Entity, String?>, beginsWith value: String, options: StringFilterOptions = []) -> Self {
        excluding(predicate: predicate(keyPath: keyPath, beginsWith: value, options: options))
    }
    
    public func excluding(_ keyPath: KeyPath<Entity, String?>, endsWith value: String, options: StringFilterOptions = []) -> Self {
        excluding(predicate: predicate(keyPath: keyPath, endsWith: value, options: options))
    }
    
    public func excluding(_ keyPath: KeyPath<Entity, String?>, matches value: String, options: StringFilterOptions = []) -> Self {
        excluding(predicate: predicate(keyPath: keyPath, matches: value, options: options))
    }
    
}


#endif