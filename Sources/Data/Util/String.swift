import Foundation

public extension String {

    /// `true` when the string is empty or contains only whitespace / newlines.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

}
