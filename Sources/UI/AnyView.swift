#if canImport(SwiftUI)
import SwiftUI

public extension View {

    /// Type-erases the receiver into an `AnyView`.
    func toAnyView() -> AnyView {
        AnyView(self)
    }

}
#endif
