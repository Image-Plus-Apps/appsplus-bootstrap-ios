#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct AppAlertModifier: ViewModifier {

    @Binding var alert: AppAlert?

    func body(content: Content) -> some View {
        content
            .alert(
                alert?.title ?? "",
                isPresented: isAlertPresented,
                presenting: alert,
                actions: { alert in
                    alertButtons(for: alert)
                },
                message: { alert in
                    Text(alert.message)
                }
            )
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { alert != nil },
            set: { isPresented in
                if !isPresented {
                    alert = nil
                }
            }
        )
    }

    @ViewBuilder
    private func alertButtons(for alert: AppAlert) -> some View {
        ForEach(Array(alert.buttons.enumerated()), id: \.offset) { _, button in
            Button(
                button.title,
                role: button.role.map { swiftUIRole($0) }
            ) {
                button.action?()
            }
        }
    }

    private func swiftUIRole(_ role: AppAlert.ButtonRole) -> SwiftUI.ButtonRole {
        switch role {
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension View {

    /// Presents a native alert driven by an optional ``AppAlert`` binding.
    func appAlert(_ alert: Binding<AppAlert?>) -> some View {
        modifier(AppAlertModifier(alert: alert))
    }

}
#endif
