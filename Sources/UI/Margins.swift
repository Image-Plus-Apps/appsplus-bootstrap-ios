#if canImport(UIKit)
import UIKit

extension CGFloat {
    public enum Margin {
        case xSmall
        case small
        case medium
        case large
    }
    
    public static func margin(_ x: Margin) -> CGFloat {
        switch x {
        case .xSmall:
            return 4
        case .small:
            return 8
        case .medium:
            return 16
        case .large:
            return 32
        }
    }
}
#endif
