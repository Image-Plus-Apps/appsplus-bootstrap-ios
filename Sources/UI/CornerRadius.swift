#if canImport(UIKit)
import UIKit

public enum CornerRadius: Hashable, Sendable {
    case value(CGFloat)
    case percentage(CGFloat)
}

extension CornerRadius {
    
    public static let `default` = CornerRadius.value(8)
}

extension UIView {
    
    public func apply(cornerRadius: CornerRadius) {
        switch cornerRadius {
        case .value(let value):
            layer.cornerRadius = value
        case .percentage(let percentage):
            layer.cornerRadius = (bounds.height / 2) * percentage
        }
    }
}
#endif
