#if canImport(SwiftUI)
import SwiftUI

public extension View {

    /// Applies an arbitrary transform to the view and returns the result.
    ///
    /// Useful for conditionally or inline-applying modifiers that change the
    /// returned view's type (e.g. wrapping in a container) without breaking the
    /// modifier chain.
    func apply<Modified: View>(
        @ViewBuilder _ transform: (Self) -> Modified
    ) -> Modified {
        transform(self)
    }

    /// Runs a side-effecting block against the view and returns the view unchanged.
    @discardableResult
    func configure(_ block: (Self) -> Void) -> Self {
        block(self)
        return self
    }

}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public extension ToolbarContent {

    /// Applies an arbitrary transform to the toolbar content and returns the result.
    func apply<Modified: ToolbarContent>(
        @ToolbarContentBuilder _ transform: (Self) -> Modified
    ) -> Modified {
        transform(self)
    }

}
#endif
