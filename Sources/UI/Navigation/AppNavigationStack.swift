import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct AppNavigationStack<Route: Hashable, Root: View, Destination: View>: View {

    @Binding var path: NavigationPath
    @ViewBuilder var root: () -> Root
    @ViewBuilder var destination: (Route) -> Destination

    public init(path: Binding<NavigationPath>, @ViewBuilder root: @escaping () -> Root, @ViewBuilder destination: @escaping (Route) -> Destination) {
        self._path = path
        self.root = root
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $path) {
            root()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
    }
}
